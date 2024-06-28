import 'package:donationwallet/src/data/providers/chain_api.dart';

class ChainRepository {
  final ChainApiProvider chainApiProvider;

  ChainRepository(this.chainApiProvider);

  Future<int> getChainTip() async {
    try {
      final tip = await chainApiProvider.getChainTipFromApi();
      return tip;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> scanChain(String wallet) async {
    try {
      final updated = await chainApiProvider.scanChainFromApi(wallet);
      return updated;
    } catch (e) {
      rethrow;
    }
  }
}
