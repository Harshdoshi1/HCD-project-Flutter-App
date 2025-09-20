import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui' show window;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // Flag to indicate whether to use local mock data instead of real API calls
  static bool useLocalMockData = false;
  
  // The physical machine's IP address on your local network
  static const String _physicalMachineIp = '192.168.218.178';
  
  // Configure whether to use local mock data
  static Future<void> setUseLocalMockData(bool value) async {
    useLocalMockData = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_local_mock_data', value);
  }

  
  // Load configuration from SharedPreferences
  static Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    useLocalMockData = prefs.getBool('use_local_mock_data') ?? false;
  }

  /// Returns the appropriate base URL for API calls based on the platform
  static String get baseUrl {
    // If using local mock data, return a dummy URL
    if (useLocalMockData) {
      return 'http://local-mock-data/api';
    }
    // For web or desktop - use localhost
    if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return 'http://localhost:5001/api';
    }
    // For Android
    else if (Platform.isAndroid) {
      // Use actual IP address for physical device
      return 'http://$_physicalMachineIp:5001/api';
    }
    // For iOS 
    else if (Platform.isIOS) {
      // Use actual IP address for physical device
      return 'http://$_physicalMachineIp:5001/api';
    }
    // Default fallback
    return 'http://localhost:5001/api';
  }

  /// Returns the appropriate full URL for a specific endpoint
  static String getUrl(String endpoint) {
    // Remove leading slash if present
    if (endpoint.startsWith('/')) {
      endpoint = endpoint.substring(1);
    }
    
    return '$baseUrl/$endpoint';
  }
}
