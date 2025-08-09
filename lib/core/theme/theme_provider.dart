import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing app theme state
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

/// Theme notifier that manages the current theme mode with persistence
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  static const String _themeKey = 'app_theme_mode';

  /// Load theme from shared preferences
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey);
      
      if (themeIndex != null) {
        state = ThemeMode.values[themeIndex];
      }
    } catch (e) {
      // If loading fails, keep default system theme
      debugPrint('Failed to load theme preference: $e');
    }
  }

  /// Save theme to shared preferences
  Future<void> _saveTheme(ThemeMode theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, theme.index);
    } catch (e) {
      debugPrint('Failed to save theme preference: $e');
    }
  }

  /// Set light theme
  Future<void> setLightTheme() async {
    state = ThemeMode.light;
    await _saveTheme(ThemeMode.light);
  }

  /// Set dark theme
  Future<void> setDarkTheme() async {
    state = ThemeMode.dark;
    await _saveTheme(ThemeMode.dark);
  }

  /// Set system theme (follows device settings)
  Future<void> setSystemTheme() async {
    state = ThemeMode.system;
    await _saveTheme(ThemeMode.system);
  }

  /// Toggle between light and dark theme
  /// If currently on system mode, switches to light first
  Future<void> toggleTheme() async {
    switch (state) {
      case ThemeMode.light:
        await setDarkTheme();
        break;
      case ThemeMode.dark:
        await setLightTheme();
        break;
      case ThemeMode.system:
        await setLightTheme();
        break;
    }
  }

  /// Get the current theme mode display name in Hebrew
  String get currentThemeDisplayName {
    switch (state) {
      case ThemeMode.light:
        return 'מצב בהיר';
      case ThemeMode.dark:
        return 'מצב כהה';
      case ThemeMode.system:
        return 'לפי המכשיר';
    }
  }

  /// Get the current theme icon
  IconData get currentThemeIcon {
    switch (state) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.auto_mode;
    }
  }

  /// Check if current theme is dark (considering system theme)
  bool isDark(BuildContext context) {
    switch (state) {
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
  }

  /// Check if current theme is light (considering system theme)
  bool isLight(BuildContext context) {
    return !isDark(context);
  }
}

/// Provider for checking if current theme is dark
/// Useful for widgets that need to know the effective theme
final isDarkThemeProvider = Provider<bool>((ref) {
  // This will be overridden in widgets that have BuildContext
  return false;
});

/// Create a provider that depends on BuildContext for accurate theme detection
Provider<bool> isDarkThemeProviderWithContext(BuildContext context) {
  return Provider<bool>((ref) {
    final themeMode = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    return themeNotifier.isDark(context);
  });
}
