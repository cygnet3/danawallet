import 'package:danawallet/constants.dart';
import 'package:danawallet/generated/rust/api/chain.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class ChainState extends ChangeNotifier {
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

  void reset() {
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

  Future<void> updateBlindbitUrl(String blindbitUrl) async {
    // todo: make sure that url matches the network!
    Logger().i('Updating blindbit url');
    Logger().i('Old blindbit url: $_blindbitUrl');
    _blindbitUrl = blindbitUrl;
    Logger().i('New blindbit url: $_blindbitUrl');

    await updateChainTip();
  }
}
