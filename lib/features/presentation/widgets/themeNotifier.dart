import 'package:flutter/material.dart';

class ThemeNotifier extends ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }

  void setDark(bool value) {
    _isDark = value;
    notifyListeners();
  }
}