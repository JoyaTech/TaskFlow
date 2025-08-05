import 'package:flutter/material.dart';

class LightModeColors {
  static const lightPrimary = Color(0xFF6B73FF);
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightPrimaryContainer = Color(0xFFE0E3FF);
  static const lightOnPrimaryContainer = Color(0xFF1A1B57);
  static const lightSecondary = Color(0xFF9C27B0);
  static const lightOnSecondary = Color(0xFFFFFFFF);
  static const lightTertiary = Color(0xFF26A69A);
  static const lightOnTertiary = Color(0xFFFFFFFF);
  static const lightError = Color(0xFFE57373);
  static const lightOnError = Color(0xFFFFFFFF);
  static const lightErrorContainer = Color(0xFFFFEBEE);
  static const lightOnErrorContainer = Color(0xFFB71C1C);
  static const lightInversePrimary = Color(0xFFB8C3FF);
  static const lightShadow = Color(0xFF000000);
  static const lightSurface = Color(0xFFFBFBFF);
  static const lightOnSurface = Color(0xFF1A1C1E);
  static const lightAppBarBackground = Color(0xFFE0E3FF);
  static const lightSuccess = Color(0xFF4CAF50);
  static const lightCalm = Color(0xFFE8F5E8);
}

class DarkModeColors {
  static const darkPrimary = Color(0xFFB8C3FF);
  static const darkOnPrimary = Color(0xFF1A1B57);
  static const darkPrimaryContainer = Color(0xFF3D4BAE);
  static const darkOnPrimaryContainer = Color(0xFFE0E3FF);
  static const darkSecondary = Color(0xFFCE93D8);
  static const darkOnSecondary = Color(0xFF4A148C);
  static const darkTertiary = Color(0xFF80CBC4);
  static const darkOnTertiary = Color(0xFF00695C);
  static const darkError = Color(0xFFEF9A9A);
  static const darkOnError = Color(0xFF8D0002);
  static const darkErrorContainer = Color(0xFFA43A15);
  static const darkOnErrorContainer = Color(0xFFFFDBD6);
  static const darkInversePrimary = Color(0xFF6B73FF);
  static const darkShadow = Color(0xFF000000);
  static const darkSurface = Color(0xFF111318);
  static const darkOnSurface = Color(0xFFE3E2E6);
  static const darkAppBarBackground = Color(0xFF3D4BAE);
  static const darkSuccess = Color(0xFF81C784);
  static const darkCalm = Color(0xFF2E7D32);
}

class FontSizes {
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 24.0;
  static const double headlineSmall = 22.0;
  static const double titleLarge = 22.0;
  static const double titleMedium = 18.0;
  static const double titleSmall = 16.0;
  static const double labelLarge = 16.0;
  static const double labelMedium = 14.0;
  static const double labelSmall = 12.0;
  static const double bodyLarge = 20.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
}

ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    primary: LightModeColors.lightPrimary,
    onPrimary: LightModeColors.lightOnPrimary,
    primaryContainer: LightModeColors.lightPrimaryContainer,
    onPrimaryContainer: LightModeColors.lightOnPrimaryContainer,
    secondary: LightModeColors.lightSecondary,
    onSecondary: LightModeColors.lightOnSecondary,
    tertiary: LightModeColors.lightTertiary,
    onTertiary: LightModeColors.lightOnTertiary,
    error: LightModeColors.lightError,
    onError: LightModeColors.lightOnError,
    errorContainer: LightModeColors.lightErrorContainer,
    onErrorContainer: LightModeColors.lightOnErrorContainer,
    inversePrimary: LightModeColors.lightInversePrimary,
    shadow: LightModeColors.lightShadow,
    surface: LightModeColors.lightSurface,
    onSurface: LightModeColors.lightOnSurface,
  ),
  brightness: Brightness.light,
  appBarTheme: AppBarTheme(
    backgroundColor: LightModeColors.lightAppBarBackground,
    foregroundColor: LightModeColors.lightOnPrimaryContainer,
    elevation: 0,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'NotoSansHebrew',
      fontSize: FontSizes.displayLarge,
      fontWeight: FontWeight.normal,
    ),
    displayMedium: TextStyle(
      fontFamily: 'NotoSansHebrew',
      fontSize: FontSizes.displayMedium,
      fontWeight: FontWeight.normal,
    ),
    displaySmall: TextStyle(
      fontFamily: 'NotoSansHebrew',
      fontSize: FontSizes.displaySmall,
      fontWeight: FontWeight.w600,
    ),
    headlineLarge: TextStyle(
      fontFamily: 'NotoSerifHebrew',
      fontSize: FontSizes.headlineLarge,
      fontWeight: FontWeight.normal,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'NotoSerifHebrew',
      fontSize: FontSizes.headlineMedium,
      fontWeight: FontWeight.w500,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'NotoSerifHebrew',
      fontSize: FontSizes.headlineSmall,
      fontWeight: FontWeight.bold,
    ),
    titleLarge: TextStyle(
      fontFamily: 'NotoSansHebrew',
      fontSize: FontSizes.titleLarge,
      fontWeight: FontWeight.w500,
    ),
    titleMedium: TextStyle(
      fontFamily: 'NotoSansHebrew',
      fontSize: FontSizes.titleMedium,
      fontWeight: FontWeight.w500,
    ),
    titleSmall: TextStyle(
      fontFamily: 'NotoSansHebrew',
      fontSize: FontSizes.titleSmall,
      fontWeight: FontWeight.w500,
    ),
    labelLarge: TextStyle(
      fontFamily: 'NotoSansHebrew',
      fontSize: FontSizes.labelLarge,
      fontWeight: FontWeight.w500,
    ),
    labelMedium: TextStyle(
      fontFamily: 'NotoSansHebrew',
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: TextStyle(
      fontFamily: 'NotoSansHebrew',
      fontSize: FontSizes.labelSmall,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'NotoSansHebrew',
      fontSize: FontSizes.bodyLarge,
      fontWeight: FontWeight.normal,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'NotoSansHebrew',
      fontSize: FontSizes.bodyMedium,
      fontWeight: FontWeight.normal,
    ),
    bodySmall: TextStyle(
      fontFamily: 'NotoSansHebrew',
      fontSize: FontSizes.bodySmall,
      fontWeight: FontWeight.normal,
    ),
  ),
);

ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.dark(
    primary: DarkModeColors.darkPrimary,
    onPrimary: DarkModeColors.darkOnPrimary,
    primaryContainer: DarkModeColors.darkPrimaryContainer,
    onPrimaryContainer: DarkModeColors.darkOnPrimaryContainer,
    secondary: DarkModeColors.darkSecondary,
    onSecondary: DarkModeColors.darkOnSecondary,
    tertiary: DarkModeColors.darkTertiary,
    onTertiary: DarkModeColors.darkOnTertiary,
    error: DarkModeColors.darkError,
    onError: DarkModeColors.darkOnError,
    errorContainer: DarkModeColors.darkErrorContainer,
    onErrorContainer: DarkModeColors.darkOnErrorContainer,
    inversePrimary: DarkModeColors.darkInversePrimary,
    shadow: DarkModeColors.darkShadow,
    surface: DarkModeColors.darkSurface,
    onSurface: DarkModeColors.darkOnSurface,
  ),
  brightness: Brightness.dark,
  appBarTheme: AppBarTheme(
    backgroundColor: DarkModeColors.darkAppBarBackground,
    foregroundColor: DarkModeColors.darkOnPrimaryContainer,
    elevation: 0,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'NotoSansHebrew',
      fontSize: FontSizes.displayLarge,
      fontWeight: FontWeight.normal,
    ),
    displayMedium: TextStyle(
      fontFamily: 'NotoSansHebrew',
      fontSize: FontSizes.displayMedium,
      fontWeight: FontWeight.normal,
    ),
    displaySmall: TextStyle(
      fontFamily: 'NotoSansHebrew',
      fontSize: FontSizes.displaySmall,
      fontWeight: FontWeight.w600,
    ),
    headlineLarge: TextStyle(
      fontFamily: 'NotoSerifHebrew',
      fontSize: FontSizes.headlineLarge,
      fontWeight: FontWeight.normal,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'NotoSerifHebrew',
      fontSize: FontSizes.headlineMedium,
      fontWeight: FontWeight.w500,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'NotoSerifHebrew',
      fontSize: FontSizes.headlineSmall,
      fontWeight: FontWeight.bold,
    ),
    titleLarge: TextStyle(
      fontFamily: 'NotoSansHebrew',
      fontSize: FontSizes.titleLarge,
      fontWeight: FontWeight.w500,
    ),
    titleMedium: TextStyle(
      fontFamily: 'NotoSansHebrew',
      fontSize: FontSizes.titleMedium,
      fontWeight: FontWeight.w500,
    ),
    titleSmall: TextStyle(
      fontFamily: 'NotoSansHebrew',
      fontSize: FontSizes.titleSmall,
      fontWeight: FontWeight.w500,
    ),
    labelLarge: TextStyle(
      fontFamily: 'NotoSansHebrew',
      fontSize: FontSizes.labelLarge,
      fontWeight: FontWeight.w500,
    ),
    labelMedium: TextStyle(
      fontFamily: 'NotoSansHebrew',
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: TextStyle(
      fontFamily: 'NotoSansHebrew',
      fontSize: FontSizes.labelSmall,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'NotoSansHebrew',
      fontSize: FontSizes.bodyLarge,
      fontWeight: FontWeight.normal,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'NotoSansHebrew',
      fontSize: FontSizes.bodyMedium,
      fontWeight: FontWeight.normal,
    ),
    bodySmall: TextStyle(
      fontFamily: 'NotoSansHebrew',
      fontSize: FontSizes.bodySmall,
      fontWeight: FontWeight.normal,
    ),
  ),
);
