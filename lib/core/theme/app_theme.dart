import 'package:flutter/material.dart';

/// ChatMeal App Theme
/// Colors based on the brand: dark teal-green and golden yellow/orange
class AppTheme {
  // Brand Colors
  static const Color darkTealGreen = Color(0xFF1A4D4D); // Dark teal-green
  static const Color goldenYellow = Color(0xFFF4A460); // Golden yellow/orange
  static const Color goldenOrange = Color(0xFFFFB347); // Lighter golden
  static const Color black = Color(0xFF000000); // Black background
  static const Color white = Color(0xFFFFFFFF); // White text/icons

  // Accent Colors
  static const Color lightTeal = Color(0xFF2D6D6D); // Lighter teal variant
  static const Color darkGolden = Color(0xFFD98B3D); // Darker golden variant

  /// Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: darkTealGreen,
        secondary: goldenYellow,
        surface: white,
        error: Colors.red,
        onPrimary: white,
        onSecondary: black,
        onSurface: black,
        onError: white,
      ),
      scaffoldBackgroundColor: black,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkTealGreen,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: goldenYellow,
          foregroundColor: black,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: white,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: white,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: white,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: white,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: white,
        ),
      ),
    );
  }

  /// Dark Theme (can be customized differently if needed)
  static ThemeData get darkTheme {
    return lightTheme; // For now, using same theme
  }
}
