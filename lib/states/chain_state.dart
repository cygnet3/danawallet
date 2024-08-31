import 'package:donationwallet/rust/api/chain.dart';
import 'package:donationwallet/services/preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class ChainState extends ChangeNotifier {
  int? _tip;

  ChainState();

  Future<void> initialize() async {
    final url = await SettingsService().getBlindbitUrl();

    if (url != null) {
      _tip = await getChainHeight(blindbitUrl: url);
      print('initialized with tip: $_tip');
    } else {
      Logger()
          .w('Attempted to initialize chain state before blindbit url was set');
    }
  }

  void reset() {
    _tip = null;
  }

  bool _isInitialized() {
    return _tip != null;
  }

  int get tip {
    if (_isInitialized()) {
      return _tip!;
    } else {
      throw Exception('attempted to get chain tip without initializing');
    }
  }

  Future<void> updateChainTip() async {
    if (_isInitialized()) {
      final url = await SettingsService().getBlindbitUrl();

      _tip = await getChainHeight(blindbitUrl: url!);
      print('updating tip: $_tip');

      notifyListeners();
    } else {
      throw Exception('attempted to update chain tip without initializing');
    }
  }
}
