import 'package:danawallet/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  final SharedPreferencesAsync prefs = SharedPreferencesAsync();

  Future<void> defaultSettings(Network network) async {
    final String blindbitUrl = network.getDefaultBlindbitUrl();
    await SettingsService().setBlindbitUrl(blindbitUrl);
    await SettingsService().setDustLimit(defaultDustLimit);
  }

  Future<void> resetAll() async {
    await prefs.clear(allowList: {'blindbitUrl', 'dustLimit'});
  }

  Future<void> setBlindbitUrl(String url) async {
    return await prefs.setString('blindbitUrl', url);
  }

  Future<String?> getBlindbitUrl() async {
    return await prefs.getString('blindbitUrl');
  }

  Future<void> setDustLimit(int value) async {
    return await prefs.setInt('dustLimit', value);
  }

  Future<int?> getDustLimit() async {
    return await prefs.getInt('dustLimit');
  }
}
