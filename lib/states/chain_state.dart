import 'package:donationwallet/rust/api/chain.dart';
import 'package:flutter/material.dart';

class ChainState extends ChangeNotifier {
  String? _network;
  int? _tip;

  ChainState();

  Future<void> initialize(String network) async {
    _network = network;
    _tip = await getChainHeight(network: network);

    print('initialized with tip: $_tip');
  }

  void reset() {
    _network = null;
    _tip = null;
  }

  bool _isInitialized() {
    return _network != null && _tip != null;
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
      _tip = await getChainHeight(network: _network!);
      print('updating tip: $_tip');

      notifyListeners();
    } else {
      throw Exception('attempted to update chain tip without initializing');
    }
  }
}
