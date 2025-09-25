import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../utils/api_config.dart';

class AuthService {
  // Get base URL from centralized API config
  static String get baseUrl => ApiConfig.baseUrl;

  Future<Map<String, dynamic>> login(String email, String enrollmentNumber, BuildContext context) async {
    try {
      print('Attempting to log in with email: $email and enrollment number: $enrollmentNumber');
      
      // Check if we're using local mock data mode
      if (ApiConfig.useLocalMockData) {
        print('Using local mock data for login');
        
        // Create mock user data for testing
        final User mockUser = User(
          id: '1',
          name: 'Test Student',
          email: email,
          enrollmentNumber: enrollmentNumber,
          role: 'student',
          currentSemester: 6,  // Default to semester 6
          batch: '2023',
          hardwarePoints: 25,
          softwarePoints: 30,
        );
        
        // Update the user provider
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.setUser(mockUser);
        
        // Return a success response with the mock user
        return {
          'success': true,
          'message': 'Logged in using local mock data',
          'token': 'mock-token-for-testing',
          'user': mockUser
        };
      }
      
      // Normal API login if not using mock data
      // Get proper URL for the current platform
      final loginUrl = ApiConfig.getUrl('students/login');
      print('Using login URL: $loginUrl');
      
      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'enrollmentNumber': enrollmentNumber,
        }),
      ).timeout(const Duration(seconds: 15));

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.body.isEmpty) {
        throw Exception('Empty response from server');
      }

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        print('Login successful, parsing response data');
        
        // Debug print the user data
        print('User data from response: ${responseData['user']}');
        
        if (responseData['token'] == null) {
          throw Exception('Token not found in response');
        }

        if (responseData['user'] == null) {
          throw Exception('User data not found in response');
        }

        // Create user object and set it in provider
        final user = User.fromJson(responseData['user']);
        print('User object created successfully: ${user.name}, Semester: ${user.currentSemester}');
        
        Provider.of<UserProvider>(context, listen: false).setUser(user);

        return {
          'token': responseData['token'],
          'user': user,
          'message': responseData['message'] ?? 'Login successful',
        };
      } else {
        print('Login failed with status code: ${response.statusCode}');
        throw Exception(responseData['message'] ?? 'Failed to login');
      }
    } catch (e) {
      print('Login error: ${e.toString()}');
      throw Exception('Login failed: ${e.toString()}');
    }
  }
}
