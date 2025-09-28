import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'constants/app_theme.dart';
import 'providers/user_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_page.dart';
import 'utils/api_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize API configuration
  await ApiConfig.loadConfig();
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'The Ictians',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: SplashScreen(toggleTheme: _toggleTheme),
        routes: {
          '/login': (context) => LoginPage(toggleTheme: _toggleTheme),
          '/splash': (context) => SplashScreen(toggleTheme: _toggleTheme),
        },
      ),
    );
  }
}