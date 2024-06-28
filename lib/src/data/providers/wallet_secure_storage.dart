import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

class WalletSecureStorageProvider {
  final FlutterSecureStorage secureStorage;

  WalletSecureStorageProvider(this.secureStorage);

  Future<void> saveWalletToSecureStorage(String label, String spWallet) async {
    try {
      await secureStorage.write(key: label, value: spWallet);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> rmWalletFromSecureStorage(String label) async {
    final wallet = await secureStorage.read(key: label);

    if (wallet == null) {
      throw Exception("Wallet $label doesn't exist");
    }

    await secureStorage.write(key: label, value: null);

    return wallet;
  }

  Future<String> getWalletFromSecureStorage(String label) async {
    final wallet = await secureStorage.read(key: label);

    if (wallet == null) {
      throw Exception("Wallet $label doesn't exist");
    }

    return wallet;
  }
}
