import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/dashboard.dart';
import 'screens/profile_screen.dart';
import 'screens/rankings_screen.dart';
import 'screens/subjects_screen.dart';
import 'constants/app_theme.dart';
import 'screens/main_navigation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  
  bool _isDarkMode = true;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override 
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Ictians',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        // Handle navigation with arguments
        if (settings.name == '/') {
          // Extract the tab index from the arguments if provided
          final tabIndex = settings.arguments as int?;
          return MaterialPageRoute(
            builder: (context) => MainNavigation(
              toggleTheme: _toggleTheme,
              initialTabIndex: tabIndex ?? 0,
            ),
          );
        }
        return null;
      },
    );
  }
}