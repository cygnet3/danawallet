import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _keyWalletBlob = "wallet";
const String _keySeedPhrase = "seedphrase";

class WalletRepository {
  final secureStorage = const FlutterSecureStorage();

  WalletRepository();

  Future<void> reset() async {
    await secureStorage.deleteAll();
  }

  Future<String?> readWalletBlob() async {
    return await secureStorage.read(key: _keyWalletBlob);
  }

  Future<void> saveWalletBlob(String wallet) async {
    await secureStorage.write(key: _keyWalletBlob, value: wallet);
  }

  Future<String?> readSeedPhrase() async {
    return await secureStorage.read(key: _keySeedPhrase);
  }

  Future<void> saveSeedPhrase(String seedPhrase) async {
    await secureStorage.write(key: _keySeedPhrase, value: seedPhrase);
  }
}
