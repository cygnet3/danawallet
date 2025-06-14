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

  bool get initiated =>
      _tip != null && _network != null && _blindbitUrl != null;

  ChainState();

  Future<void> initialize(Network network, String blindbitUrl) async {
    // todo: make sure that url matches the network!
    _blindbitUrl = blindbitUrl;
    _network = network;
    _tip = await getChainHeight(blindbitUrl: blindbitUrl);
    Logger().i('Initializing chain state');
    Logger().i('Network: $_network');
    Logger().i('Blindbit url: $_blindbitUrl');
    Logger().i('Current tip: $_tip');
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
    Logger().i('updating tip: $_tip');

    notifyListeners();
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

      return true;
    } else {
      Logger().w('Failed to update blindbit url, wrong network');
      return false;
    }
  }
}
