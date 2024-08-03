import 'package:flutter/material.dart';

class ThemeNotifier extends ChangeNotifier {
  late ThemeData _themeData;

  ThemeNotifier(String network) : _themeData = _getThemeFromNetwork(network);

  ThemeData get themeData => _themeData;

  static ThemeData _getThemeFromNetwork(String network) {
    switch (network) {
      case 'main':
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
          useMaterial3: true,
        );
      case 'signet':
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
          useMaterial3: true,
        );
      case 'test':
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        );
      default:
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
          useMaterial3: true,
        );
    }
  }

  void setTheme(String network) {
    _themeData = _getThemeFromNetwork(network);
    notifyListeners();
  }
}
