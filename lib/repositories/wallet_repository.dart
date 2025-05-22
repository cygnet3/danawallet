import 'package:danawallet/data/enums/network.dart';
import 'package:danawallet/generated/rust/api/backup.dart';
import 'package:danawallet/generated/rust/api/history.dart';
import 'package:danawallet/generated/rust/api/outputs.dart';
import 'package:danawallet/generated/rust/api/wallet.dart';
import 'package:danawallet/generated/rust/api/wallet/setup.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// secure storage
const String _keyWalletBlob = "wallet"; // deprecated; remove this later
const String _keyScanSk = "scansk";
const String _keySpendKey = "spendkey";
const String _keySeedPhrase = "seedphrase";

// non secure storage
// this will likely replaced by an sql database in the future
const String _keyBirthday = "birthday";
const String _keyNetwork = "network";
const String _keyTxHistory = "txhistory";
const String _keyOwnedOutputs = "ownedoutputs";
const String _keyLastScan = "lastscan";

class WalletRepository {
  final secureStorage = const FlutterSecureStorage();
  final nonSecureStorage = SharedPreferencesAsync();

  // private constructor
  WalletRepository._();

  // singleton class
  static final instance = WalletRepository._();

  Future<void> reset() async {
    // delete secure storage
    await secureStorage.deleteAll();

    // delete non secure storage
    await nonSecureStorage.clear(allowList: {
      _keyNetwork,
      _keyTxHistory,
      _keyLastScan,
      _keyOwnedOutputs,
      _keyBirthday
    });
  }

  Future<SpWallet> setupWallet(
      WalletSetupResult walletSetup, Network network, int birthday) async {
    if ((await secureStorage.readAll()).isNotEmpty) {
      throw Exception('Previous wallet not properly deleted');
    }

    // save variables in storage
    final scanKey = walletSetup.scanKey;
    final spendKey = walletSetup.spendKey;
    final seedPhrase = walletSetup.mnemonic;

    // insert new values
    await secureStorage.write(key: _keyScanSk, value: scanKey.encode());
    await secureStorage.write(key: _keySpendKey, value: spendKey.encode());
    await nonSecureStorage.setInt(_keyBirthday, birthday);
    await nonSecureStorage.setString(_keyNetwork, network.name);

    if (seedPhrase != null) {
      await secureStorage.write(key: _keySeedPhrase, value: seedPhrase);
    }

    // set default values for new wallet
    await saveLastScan(birthday);
    await saveHistory(TxHistory.empty());
    await saveOwnedOutputs(OwnedOutputs.empty());

    // check if creation was successful by reading wallet
    final wallet = await readWallet();
    return wallet!;
  }

  Future<SpWallet?> readWallet() async {
    // read scan and spend key. if these are present, the entire wallet should be present
    final scanKey = await readScanKey();
    final spendKey = await readSpendKey();

    if (scanKey != null && spendKey != null) {
      final birthday = await nonSecureStorage.getInt(_keyBirthday);
      final network = await readNetwork();

      return SpWallet(
          scanKey: scanKey,
          spendKey: spendKey,
          birthday: birthday!,
          network: network.toBitcoinNetwork);
    } else {
      // this case is for backwards compatibility, to convert the wallet blob into separate
      // values.
      // todo: remove this
      final walletBlob = await secureStorage.read(key: _keyWalletBlob);
      if (walletBlob != null) {
        final wallet = SpWallet.decode(encodedWallet: walletBlob);
        final scanKey = wallet.getScanKey();
        final spendKey = wallet.getSpendKey();
        final birthday = wallet.getBirthday();

        // insert new values
        await secureStorage.write(key: _keyScanSk, value: scanKey.encode());
        await secureStorage.write(key: _keySpendKey, value: spendKey.encode());
        await nonSecureStorage.setInt(_keyBirthday, birthday);

        // these values may be present in the wallet blob (for older versions)
        // we have to save these too
        if ((await nonSecureStorage.getString(_keyTxHistory)) == null) {
          await saveHistory(wallet.getWalletTxHistory()!);
        }

        if ((await nonSecureStorage.getString(_keyOwnedOutputs)) == null) {
          await saveOwnedOutputs(wallet.getWalletOwnedOutputs()!);
        }

        if ((await nonSecureStorage.getInt(_keyLastScan)) == null) {
          await saveLastScan(wallet.getWalletLastScan()!);
        }

        // remove old (deprecated) value
        await secureStorage.delete(key: _keyWalletBlob);

        return wallet;
      } else {
        return null;
      }
    }
  }

  Future<ApiScanKey?> readScanKey() async {
    final encoded = await secureStorage.read(key: _keyScanSk);

    if (encoded != null) {
      return ApiScanKey.decode(encoded: encoded);
    } else {
      return null;
    }
  }

  Future<ApiSpendKey?> readSpendKey() async {
    final encoded = await secureStorage.read(key: _keySpendKey);

    if (encoded != null) {
      return ApiSpendKey.decode(encoded: encoded);
    } else {
      return null;
    }
  }

  Future<String?> readSeedPhrase() async {
    return await secureStorage.read(key: _keySeedPhrase);
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

  Future<void> saveHistory(TxHistory history) async {
    return await nonSecureStorage.setString(_keyTxHistory, history.encode());
  }

  Future<TxHistory> readHistory() async {
    final encodedHistory = await nonSecureStorage.getString(_keyTxHistory);
    return TxHistory.decode(encodedHistory: encodedHistory!);
  }

  Future<void> saveLastScan(int lastScan) async {
    await nonSecureStorage.setInt(_keyLastScan, lastScan);
  }

  Future<int> readLastScan() async {
    final lastScan = await nonSecureStorage.getInt(_keyLastScan);
    return lastScan!;
  }

  Future<void> saveOwnedOutputs(OwnedOutputs ownedOutputs) async {
    await nonSecureStorage.setString(_keyOwnedOutputs, ownedOutputs.encode());
  }

  Future<OwnedOutputs> readOwnedOutputs() async {
    final encodedOutputs = await nonSecureStorage.getString(_keyOwnedOutputs);
    return OwnedOutputs.decode(encodedOutputs: encodedOutputs!);
  }

  Future<WalletBackup> createWalletBackup() async {
    final wallet = await readWallet();
    final history = await readHistory();
    final outputs = await readOwnedOutputs();
    final seedPhrase = await readSeedPhrase();
    final lastScan = await readLastScan();
    final network = await readNetwork();

    return WalletBackup(
        wallet: wallet!,
        lastScan: lastScan,
        txHistory: history,
        ownedOutputs: outputs,
        seedPhrase: seedPhrase,
        network: network.name);
  }

  Future<void> restoreWalletBackup(WalletBackup backup) async {
    await reset();

    // insert new values
    await secureStorage.write(key: _keyScanSk, value: backup.scanKey.encode());
    await secureStorage.write(
        key: _keySpendKey, value: backup.spendKey.encode());
    await nonSecureStorage.setInt(_keyBirthday, backup.birthday);
    await nonSecureStorage.setString(_keyNetwork, backup.network);

    if (backup.seedPhrase != null) {
      await secureStorage.write(key: _keySeedPhrase, value: backup.seedPhrase);
    }

    await saveHistory(backup.txHistory);
    await saveOwnedOutputs(backup.ownedOutputs);
    await saveLastScan(backup.lastScan);
  }
}
