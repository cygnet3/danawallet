import 'dart:async';
import 'dart:typed_data';
import 'package:danawallet/data/enums/network.dart';
import 'package:danawallet/data/models/bip353_address.dart';
import 'package:danawallet/data/models/recipient_form_filled.dart';
import 'package:danawallet/generated/rust/api/stream.dart';
import 'package:danawallet/generated/rust/api/structs.dart';
import 'package:danawallet/generated/rust/api/wallet.dart';
import 'package:danawallet/generated/rust/api/wallet/setup.dart';
import 'package:danawallet/generated/rust/stream.dart';
import 'package:danawallet/repositories/mempool_api_repository.dart';
import 'package:danawallet/repositories/settings_repository.dart';
import 'package:danawallet/repositories/wallet_repository.dart';
import 'package:danawallet/services/bip353_resolver.dart';
import 'package:danawallet/services/dana_address_service.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class WalletState extends ChangeNotifier {
  final walletRepository = WalletRepository.instance;

  // variables that never change (unless wallet is reset)
  late Network network;
  late String receivePaymentCode;
  late String changePaymentCode;
  late int birthday;
  late int timestamp;

  // variables that change
  late ApiAmount amount;
  late ApiAmount unconfirmedChange;
  late int lastScan;
  
  // Cached data from SQLite (updated via _updateWalletState)
  late Map<String, ApiOwnedOutput> unspentOutputs;
  late List<String> outpointsToScan;
  late List<ApiRecordedTransaction> transactions;

  // this variable may change in some exceptional cases
  Bip353Address? danaAddress;

  // stream to receive updates while scanning
  late StreamSubscription scanResultSubscription;

  // private constructor
  WalletState._();

  static Future<WalletState> create() async {
    final instance = WalletState._();
    await instance._initStreams();
    return instance;
  }

  Future<void> _initStreams() async {
    scanResultSubscription = createScanResultStream().listen(((event) async {
      // Process update based on type
      switch (event) {
        case StateUpdate_NoUpdate(:final blkheight):
          // Just update last scan height
          await walletRepository.saveLastScan(blkheight);
          break;

        case StateUpdate_Update(
          :final blkheight,
          :final blkhash,
          :final foundOutputs,
          :final foundInputs
        ):
          lastScan = blkheight;

          // Process found outputs (new UTXOs we own)
          for (final found in foundOutputs) {
            final outpoint = found.outpoint.split(':');
            final txid = outpoint[0];
            final vout = int.parse(outpoint[1]);
            final output = found.output;

            // Insert output into database
            await walletRepository.insertOutput(
              txid: txid,
              vout: vout,
              blockheight: output.blockheight,
              tweak: Uint8List.fromList(output.tweak),  
              amountSat: output.amount.field0.toInt(),
              script: output.script,
              label: output.label,
            );

            // Check if this is a self-send (skip change outputs)
            final isOwnTx = await walletRepository.isOwnOutgoingTx(txid);
            if (!isOwnTx || output.label == null) {
              // Add incoming transaction
              await walletRepository.addIncomingTransaction(
                txid: txid,
                amountSat: output.amount.field0.toInt(),
                confirmationHeight: blkheight,
                confirmationBlockhash: blkhash,
              );
            }
          }

          // Process found inputs (our UTXOs being spent)
          for (final outpointStr in foundInputs) {
            final outpoint = outpointStr.split(':');
            final spentTxid = outpoint[0];
            final spentVout = int.parse(outpoint[1]);

            // Try to confirm an outgoing transaction
            final confirmed = await walletRepository.confirmOutgoingTransaction(
              spentOutpointTxid: spentTxid,
              spentOutpointVout: spentVout,
              confirmationHeight: blkheight,
              confirmationBlockhash: blkhash,
            );

            if (!confirmed) {
              // Unknown spend - mark output as spent without history entry
              await walletRepository.markOutputsSpentUnknown(
                spentOutpoints: [(spentTxid, spentVout, 0)],
                minedInBlock: blkhash,
              );
            }
          }

          await walletRepository.saveLastScan(lastScan);
          break;
      }

      // Update UI
      await _updateWalletState();
      notifyListeners();
    }));
  }

  Future<bool> initialize() async {
    // we check if wallet str is present in database
    final wallet = await walletRepository.readWallet();

    // if not present, we have no wallet and return false
    if (wallet == null) {
      return false;
    }

    network = await walletRepository.readNetwork();
    danaAddress = await walletRepository.readDanaAddress();

    // We try to load the wallet data blob.
    // This may fail if we make a change to the wallet data struct.
    // This case should crash the app, rather than continue.
    // If we continue, we risk the user accidentally
    // deleting their seed phrase.
    try {
      receivePaymentCode = wallet.getReceivingAddress();
      changePaymentCode = wallet.getChangeAddress();
      birthday = wallet.getBirthday();
      final int timestamp = await walletRepository.readTimestamp();

      // Older wallets may not have a timestamp, if WalletRepository.readTimestamp() returns 0, we try to resolve birthday to a timestamp
      if (timestamp == 0) {
        final mempoolApi = MempoolApiRepository(network: network);
        final block = await mempoolApi.getBlockForHash(await mempoolApi.getBlockHashForHeight(birthday));
        Logger().i("Resolved block height $birthday to timestamp ${block.timestamp}");
        await walletRepository.saveTimestamp(block.timestamp);
        this.timestamp = await walletRepository.readTimestamp();
      } else {
        this.timestamp = timestamp;
      }

      await _updateWalletState();

      return true;
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    scanResultSubscription.cancel();
    super.dispose();
  }

  Future<void> reset() async {
    danaAddress = null;
    await walletRepository.reset();
  }

  Future<void> restoreWallet(Network network, String mnemonic, int birthday, int timestamp) async {
    final args = WalletSetupArgs(
        setupType: WalletSetupType.mnemonic(mnemonic),
        network: network.toCoreArg);
    final setupResult = SpWallet.setupWallet(setupArgs: args);
    final wallet =
        await walletRepository.setupWallet(setupResult, network, birthday, timestamp);

    // fill current state variables
    receivePaymentCode = wallet.getReceivingAddress();
    changePaymentCode = wallet.getChangeAddress();
    this.birthday = birthday;
    this.timestamp = timestamp;
    this.network = network;
    await _updateWalletState();
  }

  Future<void> createNewWallet(Network network, int currentTip) async {
    int birthday = currentTip;

    int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final args = WalletSetupArgs(
        setupType: const WalletSetupType.newWallet(),
        network: network.toCoreArg);
    final setupResult = SpWallet.setupWallet(setupArgs: args);
    final wallet =
        await walletRepository.setupWallet(setupResult, network, birthday, timestamp);

    // fill current state variables
    receivePaymentCode = wallet.getReceivingAddress();
    changePaymentCode = wallet.getChangeAddress();
    this.birthday = birthday;
    this.timestamp = timestamp;
    this.network = network;
    await _updateWalletState();
  }

  Future<SpWallet> getWalletFromSecureStorage() async {
    final wallet = await walletRepository.readWallet();
    if (wallet != null) {
      return wallet;
    } else {
      throw Exception("No wallet in storage");
    }
  }

  Future<String?> getSeedPhraseFromSecureStorage() async {
    return await walletRepository.readSeedPhrase();
  }

  Future<void> resetToScanHeight(int height) async {
    lastScan = height;

    await walletRepository.resetToHeight(height);

    await _updateWalletState();
    notifyListeners();
  }

  Future<void> _updateWalletState() async {
    lastScan = await walletRepository.readLastScan();

    // Get cached data from SQLite
    final balanceSat = await walletRepository.getUnspentBalance();
    amount = ApiAmount(field0: BigInt.from(balanceSat));

    final unconfirmedChangeSat = await walletRepository.getUnconfirmedChange();
    unconfirmedChange = ApiAmount(field0: BigInt.from(unconfirmedChangeSat));

    // Cache outputs for spending and scanning
    unspentOutputs = await walletRepository.getUnspentOutputs();
    outpointsToScan = await walletRepository.getNotMinedOutpoints();
    
    // Cache transactions for UI
    transactions = await walletRepository.getAllTransactions();
  }

  Future<ApiSilentPaymentUnsignedTransaction> createUnsignedTxToThisRecipient(
      RecipientFormFilled form) async {
    final wallet = await getWalletFromSecureStorage();
    final bitcoinNetwork = network.toCoreArg;

    if (form.amount.field0 < amount.field0 - BigInt.from(546)) {
      return wallet.createNewTransaction(
          apiOutputs: unspentOutputs,
          apiRecipients: [
            ApiRecipient(
                address: form.recipient.paymentCode, amount: form.amount)
          ],
          feerate: form.feerate.toDouble(),
          network: bitcoinNetwork);
    } else {
      return wallet.createDrainTransaction(
          apiOutputs: unspentOutputs,
          wipeAddress: form.recipient.paymentCode,
          feerate: form.feerate.toDouble(),
          network: bitcoinNetwork);
    }
  }

  Future<String> signAndBroadcastUnsignedTx(
      ApiSilentPaymentUnsignedTransaction unsignedTx) async {
    final selectedOutputs = unsignedTx.selectedUtxos;

    List<String> selectedOutpoints =
        selectedOutputs.map((tuple) => tuple.$1).toList();

    final changeValue =
        unsignedTx.getChangeAmount(changeAddress: changePaymentCode);

    final feeAmount = unsignedTx.getFeeAmount();

    final recipients =
        unsignedTx.getRecipients(changeAddress: changePaymentCode);

    final finalizedTx =
        SpWallet.finalizeTransaction(unsignedTransaction: unsignedTx);

    final wallet = await getWalletFromSecureStorage();

    final signedTx = wallet.signTransaction(unsignedTransaction: finalizedTx);

    Logger().d("signed tx: $signedTx");

    String txid;
    try {
      switch (network) {
        case Network.mainnet:
          txid = await SpWallet.broadcastTx(
              tx: signedTx, network: network.toCoreArg);
          break;
        case Network.signet:
          txid = await MempoolApiRepository(network: network)
              .postTransaction(signedTx);
          break;
        case Network.regtest:
          final blindbitUrl =
              await SettingsRepository.instance.getBlindbitUrl() ??
                  Network.regtest.defaultBlindbitUrl;
          txid = await SpWallet.broadcastUsingBlindbit(
              blindbitUrl: blindbitUrl, tx: signedTx);
          break;
        default:
          throw Exception("Unsupported network");
      }
    } catch (e) {
      Logger().e('Failed to broadcast transaction: $e');
      throw Exception(
          'Unable to broadcast transaction. Please check your connection and try again.');
    }

    // Mark outputs as spent in SQLite
    for (final outpointStr in selectedOutpoints) {
      final parts = outpointStr.split(':');
      final outTxid = parts[0];
      final outVout = int.parse(parts[1]);
      await walletRepository.markOutputSpent(outTxid, outVout, txid);
    }

    // Add outgoing transaction to SQLite
    final spentOutpointsWithAmount = <(String, int, int)>[];
    for (final outpointStr in selectedOutpoints) {
      final parts = outpointStr.split(':');
      final outTxid = parts[0];
      final outVout = int.parse(parts[1]);
      final outputAmount = unspentOutputs[outpointStr]?.amount.field0.toInt() ?? 0;
      spentOutpointsWithAmount.add((outTxid, outVout, outputAmount));
    }
    
    await walletRepository.addOutgoingTransaction(
      txid: txid,
      spentOutpoints: spentOutpointsWithAmount,
      recipients: recipients,
      changeSat: changeValue.field0.toInt(),
      feeSat: feeAmount.field0.toInt(),
    );

    // refresh variables and notify listeners
    await _updateWalletState();
    notifyListeners();

    return txid;
  }

  Future<String?> createSuggestedUsername() async {
    // Generate an available dana address (without registering yet)
    return await DanaAddressService(network: network)
        .generateAvailableDanaAddress(
      paymentCode: receivePaymentCode,
      maxRetries: 5,
    );
  }

  Future<void> registerDanaAddress(String username) async {
    if (danaAddress != null) {
      throw Exception("Dana address already known");
    }

    Logger().i('Registering dana address with username: $username');
    final registeredAddress = await DanaAddressService(network: network)
        .registerUser(username: username, paymentCode: receivePaymentCode);

    // Registration successful
    Logger().i('Registration successful: $registeredAddress');

    // store registed address
    danaAddress = registeredAddress;

    // Persist the dana address to storage
    await walletRepository.saveDanaAddress(registeredAddress);
  }

  // Return value indicates whether the caller should be directed to the dana registration screen
  Future<bool> checkDanaAddressRegistrationNeeded() async {
    // regtest networks have no dana address support
    if (network == Network.regtest) {
      danaAddress = null;
      return false;
    }

    // load dana address from storage
    danaAddress = await walletRepository.readDanaAddress();

    // if a stored dana address was present, verify if it's still valid
    if (danaAddress != null) {
      try {
        final verified = await Bip353Resolver.verifyPaymentCode(
            danaAddress!, receivePaymentCode, network);

        if (verified) {
          // we have a stored address and it's valid, no need to register
          Logger().i("Stored dana address is valid");
          return false;
        } else {
          Logger()
              .w("Dana address is not pointing to our sp address, removing");
          danaAddress = null;
          // note: because we haven't found a valid address in memory, we don't return here
        }
      } catch (e) {
        // If we encounter an error while verifying the address,
        // we probably don't have a working internet connection.
        // We just assume the stored address is valid for now.
        Logger().w("Received an error while verifying dana address: $e");
        return false;
      }
    }

    // no address present in storage, this may indicate we need to register a new address
    // but first, we check if the name server already has an address for us
    Logger().i("Attempting to look up dana address");
    try {
      final lookupResult = await DanaAddressService(network: network)
          .lookupDanaAddress(receivePaymentCode);
      if (lookupResult != null) {
        Logger().i("Found dana address: $lookupResult");
        danaAddress = lookupResult;
        await walletRepository.saveDanaAddress(lookupResult);
        return false;
      } else {
        Logger().i("Did not find dana address");
        return true;
      }
    } catch (e) {
      // If we encounter an error while looking up the dana address,
      // either we don't have a working internet connection,
      // or the DNS record changed and the name server is unaware.
      // For now, we assume that the stored address is valid.
      Logger().w("Received error while looking up dana address: $e");
      return false;
    }
  }
}
