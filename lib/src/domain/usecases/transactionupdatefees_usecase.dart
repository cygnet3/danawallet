import 'package:donationwallet/src/data/repositories/newtransaction_repository.dart';
import 'package:donationwallet/src/domain/entities/transaction_entity.dart';

class TransactionUpdatefeesUsecase {
  final NewtransactionRepository newtransactionRepository;

  TransactionUpdatefeesUsecase(this.newtransactionRepository);

  Future<TransactionEntity> call(TransactionEntity transaction) async {
    try {
      final updated = newtransactionRepository.udpateFees(transaction);
      transaction.setPsbt = updated;
      return transaction;
    } catch (e) {
      rethrow;
    }
  }
}