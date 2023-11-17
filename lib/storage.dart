import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static final SecureStorageService _instance =
      SecureStorageService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  SecureStorageService._internal();

  factory SecureStorageService() {
    return _instance;
  }

  Future<void> initializeWithDefaultSettings() async {
    return await initializeWithCustomSettings(dotenv.env['DEFAULT_SPEND_PK']!,
        dotenv.env['DEFAULT_SCAN_SK']!, dotenv.env['DEFAULT_BIRTHDAY']!);
  }

  Future<void> resetWallet() async {
    await _secureStorage.write(key: 'is_initialized', value: 'false');
  }

  Future<bool> isInitialized() async {
    return await _secureStorage.read(key: 'is_initialized') == 'true';
  }

  Future<void> initializeWithCustomSettings(
      String spendPk, String scanSk, String birthday) async {
    await _secureStorage.write(key: 'spend_pk', value: spendPk);
    await _secureStorage.write(key: 'scan_sk', value: scanSk);
    await _secureStorage.write(key: 'birthday', value: birthday);
    await _secureStorage.write(key: 'network', value: 'signet');
    await _secureStorage.write(key: 'is_readonly', value: 'true');
    await _secureStorage.write(key: 'is_initialized', value: 'true');
  }

  Future<String?> read({required String key}) async {
    return await _secureStorage.read(key: key);
  }
}
