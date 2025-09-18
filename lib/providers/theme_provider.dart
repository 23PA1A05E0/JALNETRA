import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode provider for managing dark/light mode
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

/// Theme mode notifier
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const String _themeKey = 'theme_mode';
  
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  /// Load saved theme mode from SharedPreferences
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey);
      if (themeIndex != null) {
        state = ThemeMode.values[themeIndex];
      }
    } catch (e) {
      // If loading fails, use system theme
      state = ThemeMode.system;
    }
  }

  /// Save theme mode to SharedPreferences
  Future<void> _saveThemeMode(ThemeMode themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, themeMode.index);
    } catch (e) {
      // If saving fails, continue with the theme change
    }
  }

  /// Set theme mode
  void setThemeMode(ThemeMode themeMode) {
    state = themeMode;
    _saveThemeMode(themeMode);
  }

  /// Toggle between light and dark mode
  void toggleTheme() {
    switch (state) {
      case ThemeMode.light:
        setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        setThemeMode(ThemeMode.light);
        break;
      case ThemeMode.system:
        // If system, toggle to light first
        setThemeMode(ThemeMode.light);
        break;
    }
  }

  /// Get current theme mode as boolean (true = dark, false = light)
  bool get isDarkMode {
    switch (state) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        // This will be handled by the system
        return false;
    }
  }

  /// Get theme mode display name
  String get themeModeName {
    switch (state) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
}

/// Theme data provider for consistent theming
final themeDataProvider = Provider<ThemeData>((ref) {
  return ThemeData(
    primarySwatch: Colors.blue,
    primaryColor: const Color(0xFF1976D2),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1976D2),
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 2,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
  );
});

/// Dark theme data provider
final darkThemeDataProvider = Provider<ThemeData>((ref) {
  return ThemeData(
    primarySwatch: Colors.blue,
    primaryColor: const Color(0xFF1976D2),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1976D2),
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 2,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
  );
});
