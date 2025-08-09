import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized theme configuration for the application
/// Supports both light and dark modes with custom Hebrew fonts
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  /// Color scheme for light mode
  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF2563EB), // Blue-600
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFDBEAFE), // Blue-100
    onPrimaryContainer: Color(0xFF1E40AF), // Blue-700
    secondary: Color(0xFF059669), // Emerald-600
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFD1FAE5), // Emerald-100
    onSecondaryContainer: Color(0xFF065F46), // Emerald-800
    tertiary: Color(0xFFDC2626), // Red-600
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFFEE2E2), // Red-100
    onTertiaryContainer: Color(0xFF991B1B), // Red-800
    error: Color(0xFFDC2626), // Red-600
    onError: Colors.white,
    errorContainer: Color(0xFFFEE2E2), // Red-100
    onErrorContainer: Color(0xFF991B1B), // Red-800
    background: Color(0xFFFAFAFA), // Neutral-50
    onBackground: Color(0xFF111827), // Gray-900
    surface: Colors.white,
    onSurface: Color(0xFF111827), // Gray-900
    surfaceVariant: Color(0xFFF3F4F6), // Gray-100
    onSurfaceVariant: Color(0xFF6B7280), // Gray-500
    outline: Color(0xFFD1D5DB), // Gray-300
    outlineVariant: Color(0xFFE5E7EB), // Gray-200
    shadow: Colors.black26,
    scrim: Colors.black54,
    inverseSurface: Color(0xFF111827), // Gray-900
    onInverseSurface: Colors.white,
    inversePrimary: Color(0xFF93C5FD), // Blue-300
    surfaceTint: Color(0xFF2563EB), // Blue-600
  );

  /// Color scheme for dark mode
  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF60A5FA), // Blue-400
    onPrimary: Color(0xFF1E3A8A), // Blue-900
    primaryContainer: Color(0xFF1E40AF), // Blue-700
    onPrimaryContainer: Color(0xFFDBEAFE), // Blue-100
    secondary: Color(0xFF34D399), // Emerald-400
    onSecondary: Color(0xFF064E3B), // Emerald-900
    secondaryContainer: Color(0xFF065F46), // Emerald-800
    onSecondaryContainer: Color(0xFFA7F3D0), // Emerald-200
    tertiary: Color(0xFFF87171), // Red-400
    onTertiary: Color(0xFF7F1D1D), // Red-900
    tertiaryContainer: Color(0xFF991B1B), // Red-800
    onTertiaryContainer: Color(0xFFFECDD3), // Red-200
    error: Color(0xFFF87171), // Red-400
    onError: Color(0xFF7F1D1D), // Red-900
    errorContainer: Color(0xFF991B1B), // Red-800
    onErrorContainer: Color(0xFFFECDD3), // Red-200
    background: Color(0xFF0F172A), // Slate-900
    onBackground: Color(0xFFF1F5F9), // Slate-100
    surface: Color(0xFF1E293B), // Slate-800
    onSurface: Color(0xFFF1F5F9), // Slate-100
    surfaceVariant: Color(0xFF334155), // Slate-700
    onSurfaceVariant: Color(0xFF94A3B8), // Slate-400
    outline: Color(0xFF64748B), // Slate-500
    outlineVariant: Color(0xFF475569), // Slate-600
    shadow: Colors.black87,
    scrim: Colors.black87,
    inverseSurface: Color(0xFFF1F5F9), // Slate-100
    onInverseSurface: Color(0xFF0F172A), // Slate-900
    inversePrimary: Color(0xFF2563EB), // Blue-600
    surfaceTint: Color(0xFF60A5FA), // Blue-400
  );

  /// Hebrew font family name
  static const String _hebrewFontFamily = 'NotoSansHebrew';

  /// Base text theme with Hebrew fonts
  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    // Create text theme with Hebrew fonts
    return TextTheme(
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
          color: colorScheme.onSurface,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: colorScheme.onSurface,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: colorScheme.onSurface,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: colorScheme.onSurface,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: colorScheme.onSurface,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: colorScheme.onSurface,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: colorScheme.onSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          color: colorScheme.onSurface,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: colorScheme.onSurface,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          color: colorScheme.onSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          color: colorScheme.onSurface,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          color: colorScheme.onSurfaceVariant,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: colorScheme.onSurface,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: colorScheme.onSurfaceVariant,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: colorScheme.onSurfaceVariant,
        ),
    );
  }

  /// Light theme configuration
  static ThemeData get lightTheme {
    const colorScheme = _lightColorScheme;
    final textTheme = _buildTextTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      fontFamily: _hebrewFontFamily,
      
      // AppBar theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: colorScheme.surfaceTint,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
      ),

      // Floating Action Button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Elevated Button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // Outlined Button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // Text Button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // Input Decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        fillColor: colorScheme.surface,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        hintStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceVariant,
        selectedColor: colorScheme.primaryContainer,
        deleteIconColor: colorScheme.onSurfaceVariant,
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // List Tile theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        leadingAndTrailingTextStyle: textTheme.labelLarge,
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.outline;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceVariant;
        }),
      ),
    );
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    const colorScheme = _darkColorScheme;
    final textTheme = _buildTextTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      fontFamily: _hebrewFontFamily,
      
      // AppBar theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: colorScheme.surfaceTint,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
      ),

      // Floating Action Button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Elevated Button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // Outlined Button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // Text Button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // Input Decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        fillColor: colorScheme.surface,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        hintStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceVariant,
        selectedColor: colorScheme.primaryContainer,
        deleteIconColor: colorScheme.onSurfaceVariant,
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // List Tile theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        leadingAndTrailingTextStyle: textTheme.labelLarge,
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.outline;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceVariant;
        }),
      ),
    );
  }
}
