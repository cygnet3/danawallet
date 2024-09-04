import 'package:danawallet/generated/rust/api/chain.dart';
import 'package:danawallet/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class ChainState extends ChangeNotifier {
  int? _tip;

  ChainState();

  Future<void> initialize() async {
    final url = await SettingsService().getBlindbitUrl();

    if (url != null) {
      try {
        _tip = await getChainHeight(blindbitUrl: url);
        Logger().i('initialized with tip: $_tip');
      } catch (e) {
        Logger().e('Failed to get block height during initialization');
      }
    } else {
      Logger()
          .w('Attempted to initialize chain state before blindbit url was set');
    }
  }

  void reset() {
    _tip = null;
  }

  bool isInitialized() {
    return _tip != null;
  }

  int get tip {
    if (isInitialized()) {
      return _tip!;
    } else {
      throw Exception('Attempted to get chain tip without initializing');
    }
  }

  Future<void> updateChainTip() async {
    try {
      final url = await SettingsService().getBlindbitUrl();
      _tip = await getChainHeight(blindbitUrl: url!);
      Logger().i('updating tip: $_tip');

      notifyListeners();
    } catch (e) {
      Logger().e('Failed to update chain height');
    }
  }
}
