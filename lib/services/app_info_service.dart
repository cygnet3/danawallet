import 'package:package_info_plus/package_info_plus.dart';

class AppInfoService {
  final PackageInfo packageInfo;

  AppInfoService({required this.packageInfo});

  String get appVersion => packageInfo.version;

  String get buildNumber => packageInfo.buildNumber;

  String get gitHash =>
      const String.fromEnvironment('GIT_HASH', defaultValue: '');
}
