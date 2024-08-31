import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  final SharedPreferencesAsync prefs = SharedPreferencesAsync();

  Future<void> setBlindbitUrl(String url) async {
    return await prefs.setString('blindbitUrl', url);
  }

  Future<String?> getBlindbitUrl() async {
    return await prefs.getString('blindbitUrl');
  }

  void resetBlindbitUrl() async {
    await prefs.remove('blindbitUrl');
  }
}
