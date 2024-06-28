import 'package:donationwallet/src/data/repositories/wallet_repository.dart';
import 'package:donationwallet/src/data/models/sp_wallet_model.dart';

class SaveWalletUseCase {
  final WalletRepository walletRepository;

  SaveWalletUseCase(this.walletRepository);

  Future<void> call(String key, SpWallet wallet) async {
    try {
      await walletRepository.saveWallet(key, wallet);
    } catch (e) {
      rethrow;
    }
  }
}
