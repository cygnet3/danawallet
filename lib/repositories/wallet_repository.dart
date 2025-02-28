import 'package:danawallet/constants.dart';
import 'package:danawallet/generated/rust/api/history.dart';
import 'package:danawallet/generated/rust/api/outputs.dart';
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
    await nonSecureStorage.clear(allowList: {
      _keyNetwork,
      _keyTxHistory,
      _keyLastScan,
      _keyOwnedOutputs
    });
  }

  Future<SpWallet?> readWallet() async {
    final walletBlob = await secureStorage.read(key: _keyWalletBlob);
    if (walletBlob != null) {
      return SpWallet.decode(encodedWallet: walletBlob);
    } else {
      return null;
    }
  }

  Future<void> saveWallet(SpWallet wallet) async {
    final walletBlob = wallet.encode();
    await secureStorage.write(key: _keyWalletBlob, value: walletBlob);
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
      final wallet = await readWallet();
      return Network.fromBitcoinNetwork(wallet!.getNetwork());
    }
  }

  Future<void> saveNetwork(Network network) async {
    await nonSecureStorage.setString(_keyNetwork, network.name);
  }

  Future<void> saveHistory(TxHistory history) async {
    return await nonSecureStorage.setString(_keyTxHistory, history.encode());
  }

  Future<TxHistory> readHistory() async {
    final encodedHistory = await nonSecureStorage.getString(_keyTxHistory);

    if (encodedHistory != null) {
      return TxHistory.decode(encodedHistory: encodedHistory);
    } else {
      // if it's not present in storage, it must be in the wallet blob
      final wallet = await readWallet();
      final history = wallet!.getWalletTxHistory()!;

      // save history to storage
      await nonSecureStorage.setString(_keyTxHistory, history.encode());

      return history;
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
      final wallet = await readWallet();
      final lastScan = wallet!.getWalletLastScan()!;

      // save history to storage
      await nonSecureStorage.setInt(_keyLastScan, lastScan);

      return lastScan;
    }
  }

  Future<void> saveOwnedOutputs(OwnedOutputs ownedOutputs) async {
    await nonSecureStorage.setString(_keyOwnedOutputs, ownedOutputs.encode());
  }

  Future<OwnedOutputs> readOwnedOutputs() async {
    final encodedOutputs = await nonSecureStorage.getString(_keyOwnedOutputs);

    if (encodedOutputs != null) {
      return OwnedOutputs.decode(encodedOutputs: encodedOutputs);
    } else {
      // if it's not present in storage, it must be in the wallet blob
      final wallet = await readWallet();
      final outputs = wallet!.getWalletOwnedOutputs()!;

      // save history to storage
      await nonSecureStorage.setString(_keyOwnedOutputs, outputs.encode());

      return outputs;
    }
  }
}
