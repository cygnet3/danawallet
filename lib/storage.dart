import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _initialized = false;

  static final SecureStorageService _instance =
      SecureStorageService._internal();
  factory SecureStorageService() {
    _instance.initialize();
    return _instance;
  }

  SecureStorageService._internal();

  Future<void> initialize() async {
    if (!_initialized) {
      if (await _secureStorage.read(key: 'birthday') == null) {
        await _secureStorage.write(
            key: 'birthday', value: dotenv.env['DEFAULT_BIRTHDAY']);
      }
      if (await _secureStorage.read(key: 'scan_sk') == null) {
        await _secureStorage.write(
            key: 'scan_sk', value: dotenv.env['DEFAULT_SCAN_SK']);
      }
      if (await _secureStorage.read(key: 'spend_pk') == null) {
        await _secureStorage.write(
            key: 'spend_pk', value: dotenv.env['DEFAULT_SPEND_PK']);
      }
      if (await _secureStorage.read(key: 'is_testnet') == null) {
        await _secureStorage.write(
            key: 'is_testnet', value: dotenv.env['DEFAULT_IS_TESTNET']);
      }
      _initialized = true;
    }
  }

  Future<void> write({required String key, required String value}) async {
    await _initializeAndThen(() async {
      await _secureStorage.write(key: key, value: value);
    });
  }

  Future<String?> read({required String key}) async {
    return await _initializeAndThen(() async {
      return await _secureStorage.read(key: key);
    });
  }

  Future<T> _initializeAndThen<T>(Future<T> Function() action) async {
    if (!_initialized) {
      await initialize();
    }
    return await action();
  }
}
