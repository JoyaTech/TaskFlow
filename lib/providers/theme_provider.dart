import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

/// Theme mode enumeration
enum AppThemeMode {
  light,
  dark,
  system;
  
  String get displayName {
    switch (this) {
      case AppThemeMode.light:
        return 'בהיר';
      case AppThemeMode.dark:
        return 'כהה';
      case AppThemeMode.system:
        return 'מערכת';
    }
  }
  
  IconData get icon {
    switch (this) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.system:
        return Icons.brightness_auto;
    }
  }
}

/// Theme state containing current theme information
class ThemeState {
  final AppThemeMode themeMode;
  final ThemeData lightTheme;
  final ThemeData darkTheme;
  final Brightness systemBrightness;
  
  const ThemeState({
    required this.themeMode,
    required this.lightTheme,
    required this.darkTheme,
    required this.systemBrightness,
  });
  
  /// Get the effective theme based on mode and system brightness
  ThemeData get effectiveTheme {
    switch (themeMode) {
      case AppThemeMode.light:
        return lightTheme;
      case AppThemeMode.dark:
        return darkTheme;
      case AppThemeMode.system:
        return systemBrightness == Brightness.dark ? darkTheme : lightTheme;
    }
  }
  
  /// Get the effective theme mode for MaterialApp
  ThemeMode get materialThemeMode {
    switch (themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
  
  /// Check if dark theme is currently active
  bool get isDarkMode {
    switch (themeMode) {
      case AppThemeMode.light:
        return false;
      case AppThemeMode.dark:
        return true;
      case AppThemeMode.system:
        return systemBrightness == Brightness.dark;
    }
  }
  
  ThemeState copyWith({
    AppThemeMode? themeMode,
    ThemeData? lightTheme,
    ThemeData? darkTheme,
    Brightness? systemBrightness,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      lightTheme: lightTheme ?? this.lightTheme,
      darkTheme: darkTheme ?? this.darkTheme,
      systemBrightness: systemBrightness ?? this.systemBrightness,
    );
  }
  
  @override
  String toString() => 'ThemeState(mode: $themeMode, isDark: $isDarkMode)';
}

/// Theme notifier managing theme state and persistence
class ThemeNotifier extends StateNotifier<ThemeState> {
  static const String _themeKey = 'app_theme_mode';
  
  ThemeNotifier() : super(ThemeState(
    themeMode: AppThemeMode.system,
    lightTheme: lightTheme,
    darkTheme: darkTheme,
    systemBrightness: Brightness.light,
  )) {
    _loadThemeFromPreferences();
  }
  
  /// Load saved theme preference
  Future<void> _loadThemeFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey);
      
      if (themeIndex != null && themeIndex < AppThemeMode.values.length) {
        final savedTheme = AppThemeMode.values[themeIndex];
        state = state.copyWith(themeMode: savedTheme);
        print('🎨 ThemeNotifier: Loaded saved theme - $savedTheme');
      }
    } catch (e) {
      print('⚠️  ThemeNotifier: Failed to load theme preference - $e');
    }
  }
  
  /// Save theme preference
  Future<void> _saveThemeToPreferences(AppThemeMode themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, themeMode.index);
      print('🎨 ThemeNotifier: Saved theme preference - $themeMode');
    } catch (e) {
      print('⚠️  ThemeNotifier: Failed to save theme preference - $e');
    }
  }
  
  /// Change theme mode
  Future<void> setThemeMode(AppThemeMode themeMode) async {
    if (state.themeMode != themeMode) {
      state = state.copyWith(themeMode: themeMode);
      await _saveThemeToPreferences(themeMode);
      
      // Provide haptic feedback for theme changes
      await HapticFeedback.lightImpact();
      
      print('🎨 ThemeNotifier: Theme changed to $themeMode');
    }
  }
  
  /// Update system brightness (called by system)
  void updateSystemBrightness(Brightness brightness) {
    if (state.systemBrightness != brightness) {
      state = state.copyWith(systemBrightness: brightness);
      print('🌓 ThemeNotifier: System brightness updated - $brightness');
    }
  }
  
  /// Toggle between light and dark (for quick switching)
  Future<void> toggleTheme() async {
    final newMode = state.isDarkMode ? AppThemeMode.light : AppThemeMode.dark;
    await setThemeMode(newMode);
  }
  
  /// Cycle through all theme modes
  Future<void> cycleThemeMode() async {
    final currentIndex = state.themeMode.index;
    final nextIndex = (currentIndex + 1) % AppThemeMode.values.length;
    final nextMode = AppThemeMode.values[nextIndex];
    await setThemeMode(nextMode);
  }
}

/// Provider for theme state
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

/// Provider for quick theme mode access
final themeModeProvider = Provider<AppThemeMode>((ref) {
  return ref.watch(themeProvider).themeMode;
});

/// Provider for effective theme
final effectiveThemeProvider = Provider<ThemeData>((ref) {
  return ref.watch(themeProvider).effectiveTheme;
});

/// Provider for dark mode check
final isDarkModeProvider = Provider<bool>((ref) {
  return ref.watch(themeProvider).isDarkMode;
});

/// Theme-aware colors provider for dynamic theming
final themeColorsProvider = Provider<ThemeColors>((ref) {
  final themeState = ref.watch(themeProvider);
  final isDark = themeState.isDarkMode;
  
  return ThemeColors(
    primary: isDark ? DarkModeColors.darkPrimary : LightModeColors.lightPrimary,
    onPrimary: isDark ? DarkModeColors.darkOnPrimary : LightModeColors.lightOnPrimary,
    primaryContainer: isDark ? DarkModeColors.darkPrimaryContainer : LightModeColors.lightPrimaryContainer,
    onPrimaryContainer: isDark ? DarkModeColors.darkOnPrimaryContainer : LightModeColors.lightOnPrimaryContainer,
    surface: isDark ? DarkModeColors.darkSurface : LightModeColors.lightSurface,
    onSurface: isDark ? DarkModeColors.darkOnSurface : LightModeColors.lightOnSurface,
    error: isDark ? DarkModeColors.darkError : LightModeColors.lightError,
    onError: isDark ? DarkModeColors.darkOnError : LightModeColors.lightOnError,
    success: isDark ? DarkModeColors.darkSuccess : LightModeColors.lightSuccess,
    calm: isDark ? DarkModeColors.darkCalm : LightModeColors.lightCalm,
  );
});

/// Theme colors class for convenient access
class ThemeColors {
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color surface;
  final Color onSurface;
  final Color error;
  final Color onError;
  final Color success;
  final Color calm;
  
  const ThemeColors({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.surface,
    required this.onSurface,
    required this.error,
    required this.onError,
    required this.success,
    required this.calm,
  });
}
