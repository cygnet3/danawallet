import 'dart:async';
import 'package:donationwallet/src/data/models/sp_wallet_model.dart';
import 'package:donationwallet/src/domain/usecases/delete_wallet_usecase.dart';
import 'package:donationwallet/src/domain/usecases/load_wallet_usecase.dart';
import 'package:donationwallet/src/domain/usecases/save_wallet_usecase.dart';
import 'package:donationwallet/src/domain/usecases/update_wallet_usecase.dart';
import 'package:donationwallet/src/domain/entities/wallet_entity.dart';
import 'package:donationwallet/src/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class WalletNotifier extends ChangeNotifier {
  final SaveWalletUseCase saveWalletUseCase;
  final LoadWalletUseCase loadWalletUseCase;
  final DeleteWalletUseCase deleteWalletUseCase;
  final UpdateWalletUseCase updateWalletUseCase;

  WalletNotifier(this.saveWalletUseCase, this.loadWalletUseCase,
      this.deleteWalletUseCase, this.updateWalletUseCase) {
    _initialize();
  }

  Future<void> _initialize() async {
    await loadWallet(defaultLabel);
  }

  WalletEntity? _wallet;
  WalletEntity? get wallet => _wallet;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  double _progress = 0.0;
  double get progress => _progress;

  String? _error;
  String? get error => _error;

  Future<void> saveWallet(String key, SpWallet wallet) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await saveWalletUseCase(key, wallet);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadWallet(String label) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _wallet = await loadWalletUseCase(label);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> rmWallet(String label) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _wallet = await deleteWalletUseCase(label);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateWallet() async {
    _isLoading = true;
    _isScanning = true;
    _progress = 0.0;
    _error = null;
    notifyListeners();

    try {
      final updated = await updateWalletUseCase(_wallet!);
      await saveWalletUseCase(defaultLabel, updated);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isScanning = false;
      _progress = 0.0;
      notifyListeners();
    }
  }
}
