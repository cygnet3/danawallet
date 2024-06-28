import 'dart:async';
import 'package:donationwallet/src/domain/usecases/get_chain_tip_usecase.dart';
import 'package:donationwallet/src/domain/entities/chain_entity.dart';
import 'package:flutter/material.dart';

class ChainNotifier extends ChangeNotifier {
  final GetChainTipUseCase getChainTipUseCase;

  ChainNotifier(this.getChainTipUseCase);

  ChainEntity? _chain;
  ChainEntity? get chain => _chain;

  int _tip = 0;
  int get tip => _tip;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> getTip(ChainEntity wallet) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tip = await getChainTipUseCase();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
