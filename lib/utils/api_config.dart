import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // Flag to indicate whether to use local mock data instead of real API calls
  static bool useLocalMockData = false;
  
  // Production API URL - Replace with your actual Render deployment URL
  static const String _productionApiUrl = 'https://hcd-project-1.onrender.com/api';
  
  // Development/Local API configuration (kept for local development)
  static const String _localApiUrl = 'http://localhost:5001/api';
  static const String _physicalMachineIp = '10.24.61.75';
  
  // Flag to determine whether to use production or local API
  static const bool useProductionApi = true; // Set to false for local development

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
    
    // If production API is enabled, use it for all platforms
    if (useProductionApi) {
      return _productionApiUrl;
    }
    
    // Local development configuration
    // For web or desktop - use localhost
    if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return _localApiUrl;
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
    return _localApiUrl;
  }

  /// Returns the appropriate full URL for a specific endpoint
  static String getUrl(String endpoint) {
    // Remove leading slash if present
    if (endpoint.startsWith('/')) {
      endpoint = endpoint.substring(1);
    }
    
    return '$baseUrl/$endpoint';
  }

  /// Utility method to get the current API mode
  static String get currentApiMode {
    if (useLocalMockData) return 'Mock Data';
    if (useProductionApi) return 'Production (Render)';
    return 'Local Development';
  }

  /// Utility method to get the current base URL being used
  static String get currentBaseUrl => baseUrl;

  /// Method to easily switch to production mode
  static void enableProductionMode() {
    // Note: This requires changing the const value and rebuilding the app
    // For runtime switching, you'd need to make useProductionApi non-const
  }

  /// Method to easily switch to development mode  
  static void enableDevelopmentMode() {
    // Note: This requires changing the const value and rebuilding the app
    // For runtime switching, you'd need to make useProductionApi non-const
  }
}
