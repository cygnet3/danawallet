import 'dart:convert';

import 'package:donationwallet/src/data/models/sp_wallet_model.dart';
import 'package:donationwallet/src/data/repositories/chain_repository.dart';
import 'package:donationwallet/src/domain/entities/wallet_entity.dart';

class UpdateWalletUseCase {
  final ChainRepository chainRepository;

  UpdateWalletUseCase(this.chainRepository);

  Future<SpWallet> call(WalletEntity wallet) async {
    try {
      final updated = await chainRepository.scanChain(jsonEncode(wallet));
      return SpWallet.fromJson(jsonDecode(updated) as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }
}
