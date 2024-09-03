import 'package:donationwallet/constants.dart';
import 'package:flutter/material.dart';

class ThemeNotifier extends ChangeNotifier {
  late ThemeData _themeData;

  ThemeNotifier() : _themeData = _getThemeFromNetwork(null);

  ThemeData get themeData => _themeData;

  static ThemeData _getThemeFromNetwork(Network? network) {
    switch (network) {
      case Network.mainnet:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
          useMaterial3: true,
        );
      case Network.signet:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
          useMaterial3: true,
        );
      case Network.testnet:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        );
      case null:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
          useMaterial3: true,
        );
    }
  }

  void setTheme(Network? network) {
    _themeData = _getThemeFromNetwork(network);
    notifyListeners();
  }
}
