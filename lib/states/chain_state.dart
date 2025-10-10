import 'package:danawallet/data/enums/network.dart';
import 'package:danawallet/generated/rust/api/chain.dart';
import 'package:danawallet/services/synchronization_service.dart';
import 'package:danawallet/states/scan_progress_notifier.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class ChainState extends ChangeNotifier {
  late SynchronizationService _synchronizationService;

  // Indicates whether the chainstate is initialized.
  // Once initialized we can check for the availability.
  // We treat these as two separate states, because we want to allow
  // a case where the app is unable to sync the chain (e.g. when there is no internet).
  Network? _network;

  // indicates whether the chain is 'available'
  String? _blindbitUrl;
  int? _tip;

  bool get initiated => _network != null;

  bool get available => initiated && _blindbitUrl != null && _tip != null;

  ChainState();

  void initialize(Network network) {
    Logger().i('Initializing chain state');
    Logger().i('Network: $network');
    // network is not yet verified in this state, it gets vetified in 'connect'
    _network = network;
  }

  void startSyncService(
      WalletState walletState, ScanProgressNotifier scanProgress, bool immediate) {
    // start sync service & timer
    _synchronizationService = SynchronizationService(
        chainState: this, walletState: walletState, scanProgress: scanProgress);
    _synchronizationService.startSyncTimer(immediate);
  }

  /// Try connecting to blindbit service
  Future<bool> connect(String blindbitUrl) async {
    if (!initiated) {
      return false;
    }

    Logger().i('Connecting to blindbit: $blindbitUrl');
    _blindbitUrl = blindbitUrl;

    try {
      final correctNetwork = await checkNetwork(
          blindbitUrl: blindbitUrl, network: _network!.toBitcoinNetwork);

      if (!correctNetwork) {
        Logger().w('Wrong network');
        return false;
      }

      _tip = await getChainHeight(blindbitUrl: blindbitUrl);
      Logger().i('Successfully connected to blindbit, current tip: $_tip');
    } catch (e) {
      Logger().w('Connection to blindbit failed: $e');
    }
    notifyListeners();
    return available;
  }

  Future<bool> reconnect() async {
    if (_blindbitUrl == null) {
      Logger().w("Attempted to reconnect, but no blindbit url is known");
      return false;
    } else {
      return await connect(_blindbitUrl!);
    }
  }

  void reset() {
    _synchronizationService.stopSyncTimer();
    _tip = null;
    _blindbitUrl = null;
    _network = null;
  }

  int get tip {
    if (available) {
      return _tip!;
    } else {
      throw Exception('Attempted to get chain tip, but chain is unavailable');
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
    if (!available) {
      Logger().w('Cannot update chain tip: chain state not available');
      return;
    }

    try {
      _tip = await getChainHeight(blindbitUrl: _blindbitUrl!);
      Logger().i('updating tip: $_tip');
      notifyListeners();
    } catch (e) {
      Logger().e('Failed to update chain tip: $e');
    }
  }

  Future<bool> updateBlindbitUrl(String newUrl) async {
    Logger().i('Updating blindbit url');
    Logger().i('Old blindbit url: $_blindbitUrl');
    Logger().i('New blindbit url: $newUrl');
    return await connect(newUrl);
  }
}
