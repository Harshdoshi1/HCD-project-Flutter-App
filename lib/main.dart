import 'package:flutter/material.dart';
import 'screens/dashboard.dart';
import 'screens/profile_screen.dart';
import 'screens/rankings_screen.dart';
import 'screens/subjects_screen.dart';
import 'widgets/login_form.dart';
import 'constants/app_theme.dart';
import 'models/user.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Start with light mode.
  ThemeMode _themeMode = ThemeMode.light;
  User? _currentUser;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Strength',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      // Example: using a bottom navigation bar to switch between pages.
      home: _currentUser == null 
          ? LoginScreen(onLoginSuccess: (User user) {
              setState(() {
                _currentUser = user;
              });
            }) 
          : DashboardScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
  final Function(User)? onLoginSuccess;
  const LoginScreen({Key? key, this.onLoginSuccess}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: LoginForm(
          onLoginSuccess: onLoginSuccess,
        ),
      ),
    );
  }
}