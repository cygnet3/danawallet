import 'package:donationwallet/src/data/providers/newtransaction_api.dart';
import 'package:donationwallet/src/domain/entities/transaction_entity.dart';

class NewtransactionRepository {
  final NewTransactionApi newTransactionApi;

  NewtransactionRepository(this.newTransactionApi);

  String createNewPsbt(TransactionEntity transaction) {
    if (transaction.finalTx != null) {
      throw Exception("Transaction already finalized");
    } else if (transaction.psbt != null) {
      throw Exception("Psbt already existing");
    }

    return newTransactionApi.createNewPsbtApi(transaction.getSpWallet, transaction.getSelectedOutputs, transaction.getRecipients);
  }

  String udpateFees(TransactionEntity transaction) {
    if (transaction.finalTx != null) {
      throw Exception("Transaction already finalized");
    } else if (transaction.psbt == null) {
      throw Exception("No psbt");
    }

    try {
      return newTransactionApi.updateFeesApi(transaction.psbt!, transaction.getFeeRate, transaction.getFeePayer);
    } catch (e) {
      rethrow;
    }
  }

  String fillOutputs(TransactionEntity transaction) {
    if (transaction.finalTx != null) {
      throw Exception("Transaction already finalized");
    } else if (transaction.psbt == null) {
      throw Exception("No psbt");
    }

    try {
      return newTransactionApi.fillOutputsApi(transaction.spWallet, transaction.psbt!);
    } catch (e) {
      rethrow;
    }
  }
  
  String signPsbt(TransactionEntity transaction) {
    if (transaction.finalTx != null) {
      throw Exception("Transaction already finalized");
    } else if (transaction.psbt == null) {
      throw Exception("No psbt");
    }

    try {
      return newTransactionApi.signPsbtApi(transaction.spWallet, transaction.psbt!, true);
    } catch (e) {
      rethrow;
    }
  }
}
