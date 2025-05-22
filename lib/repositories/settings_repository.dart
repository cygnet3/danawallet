import 'package:danawallet/constants.dart';
import 'package:danawallet/data/enums/network.dart';
import 'package:danawallet/generated/rust/api/backup.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyBlindbitUrl = "blindbiturl";
const String _keyDustLimit = "dustlimit";

class SettingsRepository {
  final SharedPreferencesAsync prefs = SharedPreferencesAsync();

  // private constructor
  SettingsRepository._();

  // singleton instance
  static final instance = SettingsRepository._();

  Future<void> defaultSettings(Network network) async {
    final String blindbitUrl = network.getDefaultBlindbitUrl();
    await setBlindbitUrl(blindbitUrl);
    await setDustLimit(defaultDustLimit);
  }

  Future<void> resetAll() async {
    await prefs.clear(allowList: {_keyBlindbitUrl, _keyDustLimit});
  }

  Future<void> setBlindbitUrl(String url) async {
    return await prefs.setString(_keyBlindbitUrl, url);
  }

  Future<String?> getBlindbitUrl() async {
    return await prefs.getString(_keyBlindbitUrl);
  }

  Future<void> setDustLimit(int value) async {
    return await prefs.setInt(_keyDustLimit, value);
  }

  Future<int?> getDustLimit() async {
    return await prefs.getInt(_keyDustLimit);
  }

  Future<SettingsBackup> createSettingsBackup() async {
    final blindbitUrl = await getBlindbitUrl();
    final dustLimit = await getDustLimit();

    return SettingsBackup(blindbitUrl: blindbitUrl!, dustLimit: dustLimit!);
  }

  Future<void> restoreSettingsBackup(SettingsBackup backup) async {
    await resetAll();
    await setBlindbitUrl(backup.blindbitUrl);
    await setDustLimit(backup.dustLimit);
  }
}
