import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF2962FF);
  static const Color secondaryColor = Color(0xFF448AFF);
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color onPrimaryColor = Color(0xFFFFFFFF);
  static const Color onSecondaryColor = Color(0xFFFFFFFF);
  static const Color onBackgroundColor = Color(0xFF000000);
  static const Color onSurfaceColor = Color(0xFF000000);
  static const Color errorColor = Color(0xFFD32F2F);

  static ThemeData get lightTheme => ThemeData.light().copyWith(
        colorScheme: ColorScheme.light(
          primary: primaryColor,
          secondary: secondaryColor,
          background: backgroundColor,
          surface: surfaceColor,
          onPrimary: onPrimaryColor,
          onSecondary: onSecondaryColor,
          onBackground: onBackgroundColor,
          onSurface: onSurfaceColor,
          error: errorColor,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: onPrimaryColor,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardTheme(
          color: surfaceColor,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(8),
        ),
        textTheme: TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: onBackgroundColor),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: onBackgroundColor),
          displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: onBackgroundColor),
          headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onBackgroundColor),
          headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onBackgroundColor),
          titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onBackgroundColor),
          bodyLarge: TextStyle(fontSize: 16, color: onBackgroundColor),
          bodyMedium: TextStyle(fontSize: 14, color: onBackgroundColor),
          bodySmall: TextStyle(fontSize: 12, color: onBackgroundColor),
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: primaryColor,
          textTheme: ButtonTextTheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );
}
