import 'package:donationwallet/src/data/repositories/wallet_repository.dart';

class DeleteWalletUseCase {
  final WalletRepository walletRepository;

  DeleteWalletUseCase(this.walletRepository);

  Future<bool> call(String label) async {
    try {
      return await walletRepository.rmWallet(label);
    } catch (e) {
      rethrow;
    }
  }
}
