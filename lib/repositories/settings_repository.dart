import 'package:danawallet/generated/rust/api/backup.dart';
import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyBlindbitUrl = "blindbiturl";
const String _keyDustLimit = "dustlimit";
const String _keyFiatCurrency = "fiatcurrency";
const String _keyUserAlias = "useralias";
const String _keyDanaAddress = "danaaddress";

class SettingsRepository {
  final SharedPreferencesAsync prefs = SharedPreferencesAsync();

  // private constructor
  SettingsRepository._();

  // singleton instance
  static final instance = SettingsRepository._();

  Future<void> resetAll() async {
    await prefs
        .clear(allowList: {_keyBlindbitUrl, _keyDustLimit, _keyFiatCurrency, _keyUserAlias, _keyDanaAddress});
  }

  Future<void> setBlindbitUrl(String? url) async {
    if (url != null) {
      return await prefs.setString(_keyBlindbitUrl, url);
    } else {
      return await prefs.remove(_keyBlindbitUrl);
    }
  }

  Future<String?> getBlindbitUrl() async {
    return await prefs.getString(_keyBlindbitUrl);
  }

  Future<void> setDustLimit(int? value) async {
    if (value != null) {
      return await prefs.setInt(_keyDustLimit, value);
    } else {
      return await prefs.remove(_keyDustLimit);
    }
  }

  Future<int?> getDustLimit() async {
    return await prefs.getInt(_keyDustLimit);
  }

  Future<void> setFiatCurrency(FiatCurrency? currency) async {
    if (currency != null) {
      return await prefs.setString(_keyFiatCurrency, currency.name);
    } else {
      return await prefs.remove(_keyFiatCurrency);
    }
  }

  Future<FiatCurrency?> getFiatCurrency() async {
    final currency = await prefs.getString(_keyFiatCurrency);

    return currency != null ? FiatCurrency.values.byName(currency) : null;
  }

  Future<void> setUserAlias(String alias) async {
    return await prefs.setString(_keyUserAlias, alias);
  }

  Future<String?> getUserAlias() async {
    return await prefs.getString(_keyUserAlias);
  }

  Future<void> clearUserAlias() async {
    return await prefs.remove(_keyUserAlias);
  }

  Future<void> setDanaAddress(String danaAddress) async {
    return await prefs.setString(_keyDanaAddress, danaAddress);
  }

  Future<String?> getDanaAddress() async {
    return await prefs.getString(_keyDanaAddress);
  }

  Future<void> clearDanaAddress() async {
    return await prefs.remove(_keyDanaAddress);
  }

  Future<SettingsBackup> createSettingsBackup() async {
    final blindbitUrl = await getBlindbitUrl();
    final dustLimit = await getDustLimit();

    return SettingsBackup(blindbitUrl: blindbitUrl, dustLimit: dustLimit);
  }

  Future<void> restoreSettingsBackup(SettingsBackup backup) async {
    await resetAll();
    if (backup.blindbitUrl != null) {
      await setBlindbitUrl(backup.blindbitUrl!);
    }
    if (backup.dustLimit != null) {
      await setDustLimit(backup.dustLimit!);
    }
  }
}
