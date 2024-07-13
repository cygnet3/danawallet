import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

class SecureStorageProvider {
  final FlutterSecureStorage secureStorage;

  SecureStorageProvider(this.secureStorage);

  Future<void> saveWalletToSecureStorage(String label, String spWallet) async {
    try {
      await secureStorage.write(key: label, value: spWallet);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> rmWalletFromSecureStorage(String label) async {
    final wallet = await secureStorage.read(key: label);

    if (wallet == null) {
      throw Exception("Wallet $label doesn't exist");
    }

    await secureStorage.write(key: label, value: null);

    return true;
  }

  Future<String> getWalletFromSecureStorage(String label) async {
    final wallet = await secureStorage.read(key: label);

    if (wallet == null) {
      throw Exception("Wallet $label doesn't exist");
    }

    return wallet;
  }
}
