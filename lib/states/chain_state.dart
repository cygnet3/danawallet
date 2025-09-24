import 'package:danawallet/data/enums/network.dart';
import 'package:danawallet/generated/rust/api/chain.dart';
import 'package:danawallet/services/synchronization_service.dart';
import 'package:danawallet/states/scan_progress_notifier.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class ChainState extends ChangeNotifier {
  late SynchronizationService _synchronizationService;
  int? _tip;
  Network? _network;
  String? _blindbitUrl;
  bool _serviceAvailable = false;

  bool get initiated =>
      _tip != null && _network != null && _blindbitUrl != null;
  
  bool get isAvailable => _serviceAvailable;
  
  /// Retry connecting to blindbit service
  Future<bool> retryConnection() async {
    if (_blindbitUrl == null || _network == null) {
      return false;
    }
    
    try {
      _tip = await getChainHeight(blindbitUrl: _blindbitUrl!);
      _serviceAvailable = true;
      Logger().i('Successfully reconnected to blindbit');
      notifyListeners();
      
      // Restart sync service if connection restored
      // Note: This assumes sync service exists but was failing
      return true;
    } catch (e) {
      Logger().w('Retry connection failed: $e');
      return false;
    }
  }

  ChainState();

  Future<void> initialize(Network network, String blindbitUrl) async {
    // todo: make sure that url matches the network!
    _blindbitUrl = blindbitUrl;
    _network = network;
    
    try {
      _tip = await getChainHeight(blindbitUrl: blindbitUrl);
      _serviceAvailable = true;
      Logger().i('Initializing chain state');
      Logger().i('Network: $_network');
      Logger().i('Blindbit url: $_blindbitUrl');
      Logger().i('Current tip: $_tip');
      notifyListeners();
    } catch (e) {
      _serviceAvailable = false;
      Logger().e('Failed to get chain height from blindbit: $e');
      notifyListeners();
      throw e; // Re-throw so main.dart can handle it
    }
  }

  void startSyncService(
      WalletState walletState, ScanProgressNotifier scanProgress) {
    _synchronizationService = SynchronizationService(
        chainState: this, walletState: walletState, scanProgress: scanProgress);
    _synchronizationService.startSyncTimer();
  }

  void reset() {
    _synchronizationService.stopSyncTimer();
    _tip = null;
    _blindbitUrl = null;
    _network = null;
    _serviceAvailable = false;
  }

  int get tip {
    if (initiated) {
      return _tip!;
    } else {
      throw Exception('Attempted to get chain tip without initializing');
    }
  }

  Network get network {
    if (initiated) {
      return _network!;
    } else {
      throw Exception('Attempted to get current network without initializing');
    }
  }

  Future<void> updateChainTip() async {
    if (!initiated) {
      Logger().w('Cannot update chain tip: chain state not initialized');
      return;
    }
    
    try {
      _tip = await getChainHeight(blindbitUrl: _blindbitUrl!);
      Logger().i('updating tip: $_tip');
      _serviceAvailable = true;
      notifyListeners();
    } catch (e) {
      Logger().e('Failed to update chain tip: $e');
      _serviceAvailable = false;
      notifyListeners();
    }
  }

  Future<bool> updateBlindbitUrl(String blindbitUrl) async {
    final correctNetwork = await checkNetwork(
        blindbitUrl: blindbitUrl, network: _network!.toBitcoinNetwork);

    if (correctNetwork) {
      Logger().i('Updating blindbit url');
      Logger().i('Old blindbit url: $_blindbitUrl');
      _blindbitUrl = blindbitUrl;
      Logger().i('New blindbit url: $_blindbitUrl');

      await updateChainTip();
      _serviceAvailable = true;

      return true;
    } else {
      Logger().w('Failed to update blindbit url, wrong network');
      _serviceAvailable = false;
      return false;
    }
  }
}
