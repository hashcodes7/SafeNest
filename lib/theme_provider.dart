import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Aniyomi-style color themes
enum AppThemeColor {
  defaultTheme('Default', Colors.blue),
  pureBlack('Pure Black', Colors.black),
  lavender('Lavender', Colors.deepPurple),
  mocha('Mocha', Colors.brown),
  twilight('Twilight', Colors.indigo),
  crimson('Crimson', Colors.red),
  emerald('Emerald', Colors.green);

  final String name;
  final Color color;
  const AppThemeColor(this.name, this.color);
}

class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _themeColorKey = 'theme_color';

  SharedPreferences? _prefs;
  ThemeMode _themeMode = ThemeMode.system;
  AppThemeColor _themeColor = AppThemeColor.defaultTheme;

  ThemeMode get themeMode => _themeMode;
  AppThemeColor get themeColor => _themeColor;

  ThemeProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    
    final int? themeModeIndex = _prefs?.getInt(_themeModeKey);
    if (themeModeIndex != null) {
      _themeMode = ThemeMode.values[themeModeIndex];
    }

    final int? themeColorIndex = _prefs?.getInt(_themeColorKey);
    if (themeColorIndex != null) {
      _themeColor = AppThemeColor.values[themeColorIndex];
    }

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _prefs?.setInt(_themeModeKey, mode.index);
  }

  Future<void> setThemeColor(AppThemeColor color) async {
    if (_themeColor == color) return;
    _themeColor = color;
    notifyListeners();
    await _prefs?.setInt(_themeColorKey, color.index);
  }

  ThemeData get lightTheme {
    return _buildTheme(Brightness.light);
  }

  ThemeData get darkTheme {
    return _buildTheme(Brightness.dark);
  }

  ThemeData _buildTheme(Brightness brightness) {
    // If Pure Black is selected and we are in dark mode, strictly use black background.
    final bool isPureBlackDark = brightness == Brightness.dark && _themeColor == AppThemeColor.pureBlack;
    final scaffoldBackgroundColor = isPureBlackDark ? Colors.black : null;
    final surfaceColor = isPureBlackDark ? Colors.black : null;

    final baseTheme = brightness == Brightness.light ? ThemeData.light() : ThemeData.dark();

    return ThemeData(
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _themeColor.color,
        brightness: brightness,
      ).copyWith(
        surface: surfaceColor ?? baseTheme.colorScheme.surface,
      ),
      scaffoldBackgroundColor: scaffoldBackgroundColor ?? baseTheme.scaffoldBackgroundColor,
      useMaterial3: true,
      textTheme: GoogleFonts.outfitTextTheme(baseTheme.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor ?? baseTheme.appBarTheme.backgroundColor,
      ),
    );
  }
}
