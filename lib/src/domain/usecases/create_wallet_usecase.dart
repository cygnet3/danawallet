import 'dart:convert';

import 'package:donationwallet/generated/rust/api/simple.dart';
import 'package:donationwallet/src/data/models/outputs_model.dart';
import 'package:donationwallet/src/data/models/sp_client_model.dart';
import 'package:donationwallet/src/data/models/sp_wallet_model.dart';
import 'package:donationwallet/src/data/repositories/wallet_repository.dart';
import 'package:donationwallet/src/domain/entities/wallet_entity.dart';
import 'package:donationwallet/src/utils/constants.dart';

class CreateWalletUseCase {
  final WalletRepository walletRepository;

  CreateWalletUseCase(this.walletRepository);

  Future<WalletEntity> call(String label, String network, int birthday) async {
    try {
      final wallet = await setup(
        label: defaultLabel,
        mnemonic: null,
        scanKey: null,
        spendKey: null,
        birthday: birthday,
        network: network,
      );

      // final spWallet = SpWallet(client: SpClient(label: wallet., scanSk: '', spendKey: null, mnemonic: '', spReceiver: null), outputs: Outputs(walletFingerprint: [], birthday: null, lastScan: null, outputs: {}));

      // return WalletEntity(
      //   label: spWallet.client.label,
      //   address: "", // we need to add it later
      //   network: spWallet.client.spReceiver.network,
      //   balance: BigInt.zero, // we compute that from all the outputs
      //   birthday: spWallet.outputs.birthday,
      //   lastScan: spWallet.outputs.lastScan,
      //   ownedOutputs: spWallet.outputs.outputs,
      // );

      final json = jsonDecode(wallet);
      final spWallet = SpWallet.fromJson(json);
      await walletRepository.saveWallet(label, spWallet);
      return await walletRepository.getWallet(label);
    } catch (e) {
      rethrow;
    }
  }
}
