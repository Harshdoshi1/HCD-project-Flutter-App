import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:5001/api';

  Future<Map<String, dynamic>> login(String email, String enrollmentNumber, BuildContext context) async {
    try {
      print('Attempting login with email: $email and enrollment: $enrollmentNumber');
      
      final response = await http.post(
        Uri.parse('$baseUrl/students/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'enrollmentNumber': enrollmentNumber,
        }),
      );

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
