import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class StudentService {
  // Hardcoded URL for now - we're forcing localhost for web
  static final String baseUrl = 'http://localhost:5001/api';

  // Get current logged-in student profile
  Future<User> getCurrentStudent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('Authentication token not found');
      }
      
      final user = prefs.getString('user');
      if (user != null) {
        return User.fromJson(json.decode(user));
      }
      
      throw Exception('User data not found');
    } catch (e) {
      throw Exception('Failed to get current student: ${e.toString()}');
    }
  }

  // Login a student
  Future<Map<String, dynamic>> loginStudent(String email, String enrollmentNumber) async {
    try {
      debugPrint('Attempting login with email: $email and enrollment: $enrollmentNumber');
      
      // Force using localhost URL for login in browser
      final loginUrl = 'http://localhost:5001/api/students/login';
      debugPrint('Using login URL: $loginUrl');
      
      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'enrollmentNumber': enrollmentNumber,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to login student: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to login student: ${e.toString()}');
    }
  }

  // Get student details by enrollment number
  Future<Map<String, dynamic>> getStudentDetailsByEnrollment(String enrollmentNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        print('Authentication token not found, returning default values');
        return {
          'student': {
            'enrollmentNumber': enrollmentNumber,
            'name': 'Unknown',
            'email': '',
            'currentSemester': 0,
            'hardwarePoints': 0,
            'softwarePoints': 0
          },
          'academic': {
            'cpi': 0.0,
            'spi': 0.0,
            'rank': 0
          }
        };
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/studentCPI/enrollment/$enrollmentNumber'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to get student details: ${response.body}, returning default values');
        return {
          'student': {
            'enrollmentNumber': enrollmentNumber,
            'name': 'Unknown',
            'email': '',
            'currentSemester': 0,
            'hardwarePoints': 0,
            'softwarePoints': 0
          },
          'academic': {
            'cpi': 0.0,
            'spi': 0.0,
            'rank': 0
          }
        };
      }
    } catch (e) {
      print('Error getting student details: ${e.toString()}, returning default values');
      return {
        'student': {
          'enrollmentNumber': enrollmentNumber,
          'name': 'Unknown',
          'email': '',
          'currentSemester': 0,
          'hardwarePoints': 0,
          'softwarePoints': 0
        },
        'academic': {
          'cpi': 0.0,
          'spi': 0.0,
          'rank': 0
        }
      };
    }
  }

  // Get student CPI/SPI data by email
  Future<Map<String, dynamic>> getStudentAcademicDataByEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final response = await http.get(
        Uri.parse('$baseUrl/studentCPI/email/$email'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          // Extract the most recent semester data (assuming it's the last one in the list)
          final latestData = data.last;
          return {
            'cpiData': {
              'latestCPI': latestData['CPI'] ?? 0.0,
              'latestSPI': latestData['SPI'] ?? 0.0,
              'rank': latestData['Rank'] ?? 0,
              'semesterNumber': latestData['SemesterId'] ?? 0
            },
            'semesterData': data
          };
        }
      }
      
      // Return default values if response is empty or not 200
      print('No academic data found for $email or invalid response, returning defaults');
      return {
        'cpiData': {
          'latestCPI': 0.0,
          'latestSPI': 0.0,
          'rank': 0,
          'semesterNumber': 0
        },
        'semesterData': []
      };
    } catch (e) {
      print('Error getting student academic data: $e');
      throw Exception('Failed to load student academic data');
    }
  }

  // Get student component marks and subjects by email
  Future<Map<String, dynamic>> getStudentComponentMarksAndSubjects(String email) async {
    try {
      // Print debug info
      print('Making API request to get component marks for email: $email');
      
      // Ensure baseUrl is correct - for local dev, use specific IP
      final apiUrl = 'http://localhost:5001/api/studentCPI/getStudentComponentMarksAndSubjectsByEmail';
      print('API URL: $apiUrl');
      
      final requestBody = jsonEncode({'email': email});
      print('Request body: $requestBody');
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body.substring(0, min(100, response.body.length))}...');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        return result;
      } else {
        throw Exception('Failed to load data: Status ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      print('Error getting student component marks and subjects: $e');
      rethrow;
    }
  }

  // Get all students for rankings
  Future<List<dynamic>> getAllStudents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        print('Authentication token not found for getting all students, returning empty list');
        return [];
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/students/getAllStudents'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to get all students: ${response.body}, returning empty list');
        return [];
      }
    } catch (e) {
      print('Error getting all students: ${e.toString()}, returning empty list');
      return [];
    }
  }
}
