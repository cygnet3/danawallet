import 'package:donationwallet/generated/rust/api/simple.dart';
import 'package:donationwallet/src/domain/entities/transaction_entity.dart';
import 'package:donationwallet/src/domain/usecases/createtransaction_usecase.dart';
import 'package:donationwallet/src/domain/usecases/load_raw_wallet_usecase.dart';
import 'package:donationwallet/src/domain/usecases/load_wallet_usecase.dart';
import 'package:donationwallet/src/domain/usecases/transactionfilloutputs_usecase.dart';
import 'package:donationwallet/src/domain/usecases/transactionupdatefees_usecase.dart';
import 'package:flutter/material.dart';

class TransactionNotifier extends ChangeNotifier {
  final CreateTransactionUsecase createTransactionUsecase;
  final TransactionUpdatefeesUsecase transactionUpdatefeesUsecase;
  final TransactionFilloutputsUsecase transactionFilloutputsUsecase;
  final LoadRawWalletUseCase loadRawWalletUseCase;
  
  TransactionNotifier(this.createTransactionUsecase, this.transactionFilloutputsUsecase, this.transactionUpdatefeesUsecase, this.loadRawWalletUseCase);

  TransactionEntity? _transaction;
  TransactionEntity? get transaction => _transaction;

  String? _error;
  String? get error => _error;

  Future<void> newTransaction(String label, String address) async {
    _error = null;
    notifyListeners();

    final spWallet = await loadRawWalletUseCase(label);

    try {
      _transaction = TransactionEntity(spWallet: spWallet, feePayer: address);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  void rmTransaction() {
    _transaction = null;
    notifyListeners();
  }

  Map<String, OwnedOutput> getInputs() {
    _error = null;
    notifyListeners();

    try {
      if (_transaction == null) {
        throw Exception("No transaction available");
      } else {
        return _transaction!.selectedOutputs;
      }
    } catch (e) {
      _error = e.toString();
      return {};
    } finally {
      notifyListeners();
    }
  }

  BigInt getTotalAvailable() {
    _error = null;
    notifyListeners();

    try {
      if (_transaction == null) {
        throw Exception("No transaction available");
      } else {
        return _transaction!.selectedOutputs.values.fold(BigInt.zero, (acc, e) => acc + e.amount.field0);
      }
    } catch (e) {
      _error = e.toString();
      return BigInt.zero;
    } finally {
      notifyListeners();
    }
  }

  void addInput(String outpoint, OwnedOutput output) {
    _error = null;
    notifyListeners();

    try {
      if (_transaction == null) {
        throw Exception("No transaction available");
      } else {
        _transaction!.appendOutput(outpoint, output);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  int recipientsLength() {
    _error = null;
    notifyListeners();

    try {
      if (_transaction == null) {
        throw Exception("No transaction available");
      } else {
        return _transaction!.recipients.length;
      }
    } catch (e) {
      _error = e.toString();
      return 0;
    } finally {
      notifyListeners();
    }
  }

  BigInt getTotalSpent() {
    _error = null;
    notifyListeners();

    try {
      if (_transaction == null) {
        throw Exception("No transaction available");
      } else {
        return _transaction!.recipients.fold(BigInt.zero, (acc, e) => acc + e.amount.field0);
      }
    } catch (e) {
      _error = e.toString();
      return BigInt.zero;
    } finally {
      notifyListeners();
    }
  }

  void createPsbt() {
    _error = null;
    notifyListeners();

    try {
      if (_transaction == null) {
        throw Exception("No transaction available");
      } else {
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }
}