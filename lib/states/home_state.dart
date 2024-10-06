import 'package:flutter/material.dart';

class HomeState extends ChangeNotifier {
  int _currentIndex = 0;

  int get selectedIndex => _currentIndex;

  void reset() {
    _currentIndex = 0;
  }

  void showMainScreen() {
    _currentIndex = 0;
    notifyListeners();
  }

  void setIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }
}
