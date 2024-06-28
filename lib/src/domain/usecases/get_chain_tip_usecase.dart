import 'package:donationwallet/src/data/repositories/chain_repository.dart';

class GetChainTipUseCase {
  final ChainRepository chainRepository;

  GetChainTipUseCase(this.chainRepository);

  Future<int> call() async {
    try {
      return await chainRepository.getChainTip();
    } catch (e) {
      rethrow;
    }
  }
}
