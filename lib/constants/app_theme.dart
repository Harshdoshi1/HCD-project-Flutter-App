import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme Colors
  static const Color primaryColor = Color(0xFF2962FF);
  static const Color primaryColorLight = Color(0xFF82B1FF); // Newly added
  static const Color secondaryColor = Color(0xFF448AFF);
  static const Color secondaryColorLight = Color(0xFFBBDEFB); // Newly added
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color onPrimaryColor = Color(0xFFFFFFFF);
  static const Color onSecondaryColor = Color(0xFFFFFFFF);
  static const Color onBackgroundColor = Color(0xFF000000);
  static const Color onSurfaceColor = Color(0xFF000000);
  static const Color errorColor = Color(0xFFD32F2F);

  // Dark Theme Colors
  static const Color darkPrimaryColor = Color(0xFF1E88E5);
  static const Color darkPrimaryColorLight = Color(0xFF64B5F6); // Newly added
  static const Color darkSecondaryColor = Color(0xFF64B5F6);
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkSurfaceColor = Color(0xFF222222);
  static const Color darkOnPrimaryColor = Color(0xFFFFFFFF);
  static const Color darkOnSecondaryColor = Color(0xFFFFFFFF);
  static const Color darkOnBackgroundColor = Color(0xFFB0BEC5);
  static const Color darkOnSurfaceColor = Color(0xFFEEEEEE);

  // Light Theme Configuration
  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: const ColorScheme.light(
          primary: primaryColor,
          primaryContainer: primaryColorLight, // Added light variant
          secondary: secondaryColor,
          secondaryContainer: secondaryColorLight, // Added light variant
          background: backgroundColor,
          surface: surfaceColor,
          onPrimary: onPrimaryColor,
          onSecondary: onSecondaryColor,
          onBackground: onBackgroundColor,
          onSurface: onSurfaceColor,
          error: errorColor,
        ),
        appBarTheme: _appBarTheme(primaryColor, onPrimaryColor),
        cardTheme: _cardTheme(surfaceColor),
        textTheme: _textTheme(onBackgroundColor),
        buttonTheme: _buttonTheme(primaryColor),
        inputDecorationTheme: _inputDecorationTheme(surfaceColor, onSurfaceColor),
      );

  // Dark Theme Configuration
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        primaryColor: darkPrimaryColor,
        scaffoldBackgroundColor: darkBackgroundColor,
        colorScheme: const ColorScheme.dark(
          primary: darkPrimaryColor,
          primaryContainer: darkPrimaryColorLight, // Added light variant
          secondary: darkSecondaryColor,
          background: darkBackgroundColor,
          surface: darkSurfaceColor,
          onPrimary: darkOnPrimaryColor,
          onSecondary: darkOnSecondaryColor,
          onBackground: darkOnBackgroundColor,
          onSurface: darkOnSurfaceColor,
          error: errorColor,
        ),
        appBarTheme: _appBarTheme(darkSurfaceColor, darkOnSurfaceColor),
        cardTheme: _cardTheme(darkSurfaceColor),
        textTheme: _textTheme(darkOnBackgroundColor),
        buttonTheme: _buttonTheme(darkPrimaryColor),
        inputDecorationTheme: _inputDecorationTheme(darkSurfaceColor, darkOnSurfaceColor),
      );

  // AppBar Theme
  static AppBarTheme _appBarTheme(Color bgColor, Color fgColor) => AppBarTheme(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        elevation: 2,
        centerTitle: true,
      );

  // Card Theme
  static CardTheme _cardTheme(Color cardColor) => CardTheme(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(8),
      );

  // Text Theme
  static TextTheme _textTheme(Color color) => TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        bodyLarge: TextStyle(fontSize: 16, color: color),
        bodyMedium: TextStyle(fontSize: 14, color: color),
        bodySmall: TextStyle(fontSize: 12, color: color),
      );

  // Button Theme
  static ButtonThemeData _buttonTheme(Color color) => ButtonThemeData(
        buttonColor: color,
        textTheme: ButtonTextTheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      );

  // Input Decoration Theme
  static InputDecorationTheme _inputDecorationTheme(Color fillColor, Color textColor) =>
      InputDecorationTheme(
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: TextStyle(color: textColor.withOpacity(0.7)),
        labelStyle: TextStyle(color: textColor),
      );
}
