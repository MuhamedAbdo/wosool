import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'isDarkMode';
  static const String _mainDriverKey = 'mainDriver';
  static const String _tempDriverKey = 'tempDriver';
  static const String _useTempDriverKey = 'useTempDriver';

  final Box _settingsBox;

  bool _isDarkMode = false;
  String _mainDriver = "غير محدد";
  String _tempDriver = "";
  bool _useTempDriver = false;

  bool get isDarkMode => _isDarkMode;
  String get mainDriver => _mainDriver;
  String get tempDriver => _tempDriver;
  bool get useTempDriver => _useTempDriver;

  ThemeProvider() : _settingsBox = Hive.box('settings') {
    _loadSettings();
  }

  void _loadSettings() {
    _isDarkMode = _settingsBox.get(_themeKey, defaultValue: false);
    _mainDriver = _settingsBox.get(_mainDriverKey, defaultValue: "غير محدد");
    _tempDriver = _settingsBox.get(_tempDriverKey, defaultValue: "");
    _useTempDriver = _settingsBox.get(_useTempDriverKey, defaultValue: false);
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _settingsBox.put(_themeKey, _isDarkMode);
    notifyListeners();
  }

  void updateMainDriver(String driver) {
    _mainDriver = driver.isEmpty ? "غير محدد" : driver;
    _settingsBox.put(_mainDriverKey, _mainDriver);
    notifyListeners();
  }

  void updateTempDriver(String driver) {
    _tempDriver = driver;
    _settingsBox.put(_tempDriverKey, _tempDriver);
    notifyListeners();
  }

  void updateUseTempDriver(bool use) {
    _useTempDriver = use;
    _settingsBox.put(_useTempDriverKey, _useTempDriver);
    notifyListeners();
  }

  ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF4A80F0),
        scaffoldBackgroundColor: const Color(0xFFF8F9FD),
        brightness: Brightness.light,
      );

  ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF4A80F0),
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        brightness: Brightness.dark,
        cardColor: const Color(0xFF16213E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F3460),
          foregroundColor: Colors.white,
        ),
      );
}
