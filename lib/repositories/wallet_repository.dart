import 'package:danawallet/constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// secure storage
const String _keyWalletBlob = "wallet";
const String _keySeedPhrase = "seedphrase";

// non secure storage
// this will likely replaced by an sql database in the future
const String _keyNetwork = "network";

class WalletRepository {
  final secureStorage = const FlutterSecureStorage();
  final nonSecureStorage = SharedPreferencesAsync();

  WalletRepository();

  Future<void> reset() async {
    // delete secure storage
    await secureStorage.deleteAll();

    // delete non secure storage
    await nonSecureStorage.clear(allowList: {_keyNetwork});
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

  Future<Network?> readNetwork() async {
    final networkStr = await nonSecureStorage.getString(_keyNetwork);

    return networkStr != null ? Network.values.byName(networkStr) : null;
  }

  Future<void> saveNetwork(Network network) async {
    await nonSecureStorage.setString(_keyNetwork, network.name);
  }
}
