import 'package:flutter/material.dart';
import 'screens/main_navigation.dart';
import 'constants/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkTheme = false;

  void _toggleTheme() {
    setState(() {
      _isDarkTheme = !_isDarkTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ICT App',
      theme: _isDarkTheme ? ThemeData.dark() : AppTheme.lightTheme,
      home: MainNavigation(toggleTheme: _toggleTheme),
      debugShowCheckedModeBanner: false,
    );
  }
}