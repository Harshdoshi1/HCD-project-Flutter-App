import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color.fromRGBO(144, 205, 244, 1);
  static const Color primaryColorLight = Color.fromRGBO(144, 205, 244, 0.4);
  
  static ThemeData get theme => ThemeData.light().copyWith(
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
    ),
  );
}
