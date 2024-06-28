import 'package:donationwallet/src/data/repositories/wallet_repository.dart';
import 'package:donationwallet/src/domain/entities/wallet_entity.dart';

class LoadWalletUseCase {
  final WalletRepository walletRepository;

  LoadWalletUseCase(this.walletRepository);

  Future<WalletEntity> call(String label) async {
    try {
      final res = await walletRepository.getWallet(label);
      return res;
    } catch (e) {
      rethrow;
    }
  }
}
