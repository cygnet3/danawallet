import 'package:donationwallet/src/data/repositories/wallet_repository.dart';

class LoadRawWalletUseCase {
  final WalletRepository walletRepository;

  LoadRawWalletUseCase(this.walletRepository);

  Future<String> call(String label) async {
    try {
      final res = await walletRepository.getRawWallet(label);
      return res;
    } catch (e) {
      rethrow;
    }
  }
}
