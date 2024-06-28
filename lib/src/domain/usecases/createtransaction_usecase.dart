import 'package:donationwallet/src/data/repositories/newtransaction_repository.dart';
import 'package:donationwallet/src/domain/entities/transaction_entity.dart';

class CreateTransactionUsecase {
  final NewtransactionRepository newtransactionRepository;

  CreateTransactionUsecase(this.newtransactionRepository);

  Future<TransactionEntity> call(TransactionEntity transaction) async {
    try {
      final newPsbt = newtransactionRepository.createNewPsbt(transaction);
      transaction.setPsbt = newPsbt;
      return transaction;
    } catch (e) {
      rethrow;
    }
  }
}

  // String _signPsbt(
  //   String wallet,
  //   String unsignedPsbt,
  // ) {
  //   return signPsbt(encodedWallet: wallet, psbt: unsignedPsbt, finalize: true);
  // }

  // String _broadcastSignedPsbt(String signedPsbt) {
  //   try {
  //     final tx = extractTxFromPsbt(psbt: signedPsbt);
  //     print(tx);
  //     final txid = broadcastTx(tx: tx);
  //     return txid;
  //   } catch (e) {
  //     rethrow;
  //   }
  // }
