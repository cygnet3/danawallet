import 'package:danawallet/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyBlindbitUrl = "blindbiturl";
const String _keyDustLimit = "dustlimit";

class SettingsRepository {
  final SharedPreferencesAsync prefs = SharedPreferencesAsync();

  Future<void> defaultSettings(Network network) async {
    final String blindbitUrl = network.getDefaultBlindbitUrl();
    await SettingsRepository().setBlindbitUrl(blindbitUrl);
    await SettingsRepository().setDustLimit(defaultDustLimit);
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
}
