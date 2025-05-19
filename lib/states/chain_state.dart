import 'package:danawallet/constants.dart';
import 'package:danawallet/generated/rust/api/chain.dart';
import 'package:danawallet/services/logging_service.dart';
import 'package:danawallet/services/synchronization_service.dart';
import 'package:danawallet/states/scan_progress_notifier.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:flutter/material.dart';

class ChainState extends ChangeNotifier {
  late SynchronizationService _synchronizationService;
  int? _tip;
  Network? _network;
  String? _blindbitUrl;

  bool get initiated =>
      _tip != null && _network != null && _blindbitUrl != null;

  ChainState();

  Future<void> initialize(Network network, String blindbitUrl) async {
    // todo: make sure that url matches the network!
    _blindbitUrl = blindbitUrl;
    _network = network;
    _tip = await getChainHeight(blindbitUrl: blindbitUrl);
    logger.i('Initializing chain state');
    logger.i('Network: $_network');
    logger.i('Blindbit url: $_blindbitUrl');
    logger.i('Current tip: $_tip');
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
    _tip = await getChainHeight(blindbitUrl: _blindbitUrl!);
    logger.i('updating tip: $_tip');

    notifyListeners();
  }

  Future<void> updateBlindbitUrl(String blindbitUrl) async {
    // todo: make sure that url matches the network!
    logger.i('Updating blindbit url');
    logger.i('Old blindbit url: $_blindbitUrl');
    _blindbitUrl = blindbitUrl;
    logger.i('New blindbit url: $_blindbitUrl');

    await updateChainTip();
  }
}
