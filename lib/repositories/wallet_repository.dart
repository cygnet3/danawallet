import 'package:danawallet/constants.dart';
import 'package:danawallet/generated/rust/api/state.dart';
import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:danawallet/generated/rust/api/wallet.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// secure storage
const String _keyWalletBlob = "wallet";
const String _keySeedPhrase = "seedphrase";

// non secure storage
// this will likely replaced by an sql database in the future
const String _keyNetwork = "network";
const String _keyTxHistory = "txhistory";
const String _keyOwnedOutputs = "ownedoutputs";
const String _keyLastScan = "lastscan";

class WalletRepository {
  final secureStorage = const FlutterSecureStorage();
  final nonSecureStorage = SharedPreferencesAsync();

  WalletRepository();

  Future<void> reset() async {
    // delete secure storage
    await secureStorage.deleteAll();

    // delete non secure storage
    await nonSecureStorage.clear(allowList: {_keyNetwork, _keyTxHistory});
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

  Future<void> trySaveSeedPhrase(String? seedPhrase) async {
    if (seedPhrase != null) {
      await secureStorage.write(key: _keySeedPhrase, value: seedPhrase);
    }
  }

  Future<Network> readNetwork() async {
    // read network from wallet repository
    // if network is not in storage, user may be using an old wallet where
    // it was stored in the wallet blob, so  try reading from there instead
    final networkStr = await nonSecureStorage.getString(_keyNetwork);

    if (networkStr != null) {
      return Network.values.byName(networkStr);
    } else {
      final walletBlob = await readWalletBlob();
      final walletInfo = getWalletInfo(encodedWallet: walletBlob!);
      return Network.fromBitcoinNetwork(walletInfo.network!);
    }
  }

  Future<void> saveNetwork(Network network) async {
    await nonSecureStorage.setString(_keyNetwork, network.name);
  }

  Future<void> saveHistory(String history) async {
    return await nonSecureStorage.setString(_keyTxHistory, history);
  }

  Future<List<ApiRecordedTransaction>> readHistory() async {
    return parseEncodedTxHistory(encodedHistory: await readHistoryEncoded());
  }

  Future<String> readHistoryEncoded() async {
    final encodedHistory = await nonSecureStorage.getString(_keyTxHistory);

    if (encodedHistory != null) {
      return encodedHistory;
    } else {
      // if it's not present in storage, it must be in the wallet blob
      final walletBlob = await readWalletBlob();
      final encodedHistory = getWalletTxHistory(encodedWallet: walletBlob!);

      // save history to storage
      await saveHistory(encodedHistory);

      return encodedHistory;
    }
  }

  Future<void> saveLastScan(int lastScan) async {
    await nonSecureStorage.setInt(_keyLastScan, lastScan);
  }

  Future<int> readLastScan() async {
    final lastScan = await nonSecureStorage.getInt(_keyLastScan);

    if (lastScan != null) {
      return lastScan;
    } else {
      // if it's not present in storage, it must be in the wallet blob
      final walletBlob = await readWalletBlob();
      final lastScan = getWalletLastScan(encodedWallet: walletBlob!);

      // save history to storage
      await saveLastScan(lastScan);

      return lastScan;
    }
  }

  Future<void> saveOwnedOutputs(String ownedOutputs) async {
    await nonSecureStorage.setString(_keyOwnedOutputs, ownedOutputs);
  }

  Future<Map<String, ApiOwnedOutput>> readOwnedOutputs() async {
    return parseEncodedOwnedOutputs(
        encodedOutputs: await readOwnedOutputsEncoded());
  }

  Future<String> readOwnedOutputsEncoded() async {
    final encodedOutputs = await nonSecureStorage.getString(_keyOwnedOutputs);
    if (encodedOutputs != null) {
      return encodedOutputs;
    } else {
      // if it's not present in storage, it must be in the wallet blob
      final walletBlob = await readWalletBlob();
      final encodedOutputs = getWalletOwnedOutputs(encodedWallet: walletBlob!);

      // save history to storage
      await saveOwnedOutputs(encodedOutputs);

      return encodedOutputs;
    }
  }
}
