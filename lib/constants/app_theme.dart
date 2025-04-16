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
  static const Color darkPrimaryColorLight = Color(0xFF64B5F6);
  static const Color darkSecondaryColor = Color(0xFF64B5F6);
  static const Color darkBackgroundColor = Color.fromARGB(255, 0, 0, 0);
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);
  static const Color darkOnPrimaryColor = Color(0xFFFFFFFF);
  static const Color darkOnSecondaryColor = Color(0xFFFFFFFF);
  static const Color darkOnBackgroundColor = Color(0xFFE0E0E0);
  static const Color darkOnSurfaceColor = Color(0xFFEEEEEE);
  static const Color darkErrorColor = Color(0xFFCF6679);

  // Bottom Navigation Bar Theme Colors
  static Color get bottomNavigationBarSelectedItemColor => darkPrimaryColor;
  static Color get bottomNavigationBarUnselectedItemColor => darkOnSurfaceColor.withOpacity(0.6);
  static Color get bottomNavigationBarBackgroundColor => const Color.fromARGB(255, 0, 0, 0); // or Colors.black for dark theme

  // Light Theme Configuration
  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: primaryColor,
          primaryContainer: primaryColorLight,
          secondary: secondaryColor,
          secondaryContainer: secondaryColorLight,
          background: Colors.white,
          surface: Colors.white,
          onPrimary: onPrimaryColor,
          onSecondary: onSecondaryColor,
          onBackground: onBackgroundColor,
          onSurface: onSurfaceColor,
          error: errorColor,
          
        ),
        appBarTheme: _appBarTheme(primaryColor, onPrimaryColor),
        cardTheme: _cardTheme(surfaceColor),
        textTheme: _textTheme(Colors.black), 
        buttonTheme: _buttonTheme(primaryColor),
        inputDecorationTheme: _inputDecorationTheme(surfaceColor, onSurfaceColor),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: primaryColor,
          unselectedItemColor: onSurfaceColor.withOpacity(0.6),
        ),
      );

  // Dark Theme Configuration
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        primaryColor: darkPrimaryColor,
        scaffoldBackgroundColor: darkBackgroundColor,
        colorScheme: const ColorScheme.dark(
          primary: darkPrimaryColor,
          primaryContainer: darkPrimaryColorLight,
          secondary: darkSecondaryColor,
          background: Color.fromARGB(255, 0, 0, 0),
          surface: Color.fromARGB(255, 0, 0, 0),
          onPrimary: darkOnPrimaryColor,
          onSecondary: darkOnSecondaryColor,
          onBackground: darkOnBackgroundColor,
          onSurface: darkOnSurfaceColor,
          error: darkErrorColor,

        ),
        appBarTheme: _appBarTheme(darkSurfaceColor, darkOnSurfaceColor),
        cardTheme: _cardTheme(darkSurfaceColor),
        textTheme: _textTheme(Colors.white), 
        buttonTheme: _buttonTheme(darkPrimaryColor),
        inputDecorationTheme: _inputDecorationTheme(darkSurfaceColor, darkOnSurfaceColor),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: darkPrimaryColor,
          foregroundColor: darkOnPrimaryColor,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: bottomNavigationBarBackgroundColor,
          selectedItemColor: bottomNavigationBarSelectedItemColor,
          unselectedItemColor: bottomNavigationBarUnselectedItemColor,
        ),
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
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color, fontFamily: 'Helvetica'),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color, fontFamily: 'Helvetica'),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color, fontFamily: 'Helvetica'),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color, fontFamily: 'Helvetica'),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color, fontFamily: 'Helvetica'),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color, fontFamily: 'Helvetica'),
        bodyLarge: TextStyle(fontSize: 16, color: color, fontFamily: 'Helvetica'),
        bodyMedium: TextStyle(fontSize: 14, color: color, fontFamily: 'Helvetica'),
        bodySmall: TextStyle(fontSize: 12, color: color, fontFamily: 'Helvetica'),
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
