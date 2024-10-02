import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WalletRepository {
  final String keyWalletBlob = "wallet";
  final String keySeedPhrase = "seedphrase";
  final secureStorage = const FlutterSecureStorage();

  WalletRepository();

  Future<void> reset() async {
    await secureStorage.deleteAll();
  }

  Future<String?> readWalletBlob() async {
    return await secureStorage.read(key: keyWalletBlob);
  }

  Future<void> saveWalletBlob(String wallet) async {
    await secureStorage.write(key: keyWalletBlob, value: wallet);
  }

  Future<String?> readSeedPhrase() async {
    return await secureStorage.read(key: keySeedPhrase);
  }

  Future<void> saveSeedPhrase(String seedPhrase) async {
    await secureStorage.write(key: keySeedPhrase, value: seedPhrase);
  }
}
