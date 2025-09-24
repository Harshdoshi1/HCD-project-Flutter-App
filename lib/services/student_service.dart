import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/api_config.dart';

class StudentService {
  // Use ApiConfig for consistent URL configuration
  static String get baseUrl {
    return ApiConfig.baseUrl;
  }

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
      
      // Use dynamic baseUrl that works across all platforms
      final loginUrl = '$baseUrl/students/login';
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
      
      // Use dynamic baseUrl from ApiConfig
      final apiUrl = '$baseUrl/studentCPI/getStudentComponentMarksAndSubjectsByEmail';
      print('API URL: $apiUrl');
      
      final requestBody = jsonEncode({'email': email});
      print('Request body: $requestBody');
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      print('Response status code: ${response.statusCode}');
    // Use dart:math min function with proper import
    print('Response body: ${response.body.substring(0, math.min(100, response.body.length))}...');

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
  
  // Get current semester points for all students
  Future<List<dynamic>> getAllStudentsCurrentSemesterPoints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        print('Authentication token not found for getting student points, returning empty list');
        return [];
      }
      
      // Get all students first to have their enrollment numbers and semesters
      final students = await getAllStudents();
      if (students.isEmpty) {
        return [];
      }
      
      // Process each student to get their points
      final List<Map<String, dynamic>> results = [];
      
      for (var student in students) {
        final enrollmentNumber = student['enrollmentNumber'];
        final semester = student['currnetsemester'] ?? student['currentSemester'] ?? 1;
        
        // Use the fetchEventsbyEnrollandSemester endpoint
        try {
          final response = await http.post(
            Uri.parse('$baseUrl/events/fetchEventsbyEnrollandSemester'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({
              'enrollmentNumber': enrollmentNumber,
              'semester': semester.toString()
            }),
          );
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            
            // Calculate totals
            int totalCocurricular = 0;
            int totalExtracurricular = 0;
            
            if (data is List) {
              for (var activity in data) {
                totalCocurricular += int.parse(activity['totalCocurricular']?.toString() ?? '0');
                totalExtracurricular += int.parse(activity['totalExtracurricular']?.toString() ?? '0');
              }
            } else if (data is Map && data.containsKey('totalCocurricular')) {
              totalCocurricular = int.parse(data['totalCocurricular']?.toString() ?? '0');
              totalExtracurricular = int.parse(data['totalExtracurricular']?.toString() ?? '0');
            }
            
            // Add to results
            results.add({
              'studentId': student['id'],
              'name': student['name'],
              'email': student['email'],
              'enrollmentNumber': enrollmentNumber,
              'semester': semester,
              'totalCocurricular': totalCocurricular,
              'totalExtracurricular': totalExtracurricular,
              'activityData': data
            });
          }
        } catch (e) {
          print('Error getting points for student $enrollmentNumber: $e');
          // Add student with zero points
          results.add({
            'studentId': student['id'],
            'name': student['name'],
            'email': student['email'],
            'enrollmentNumber': enrollmentNumber,
            'semester': semester,
            'totalCocurricular': 0,
            'totalExtracurricular': 0,
            'activityData': []
          });
        }
      }
      
      return results;
    } catch (e) {
      print('Error getting student points: ${e.toString()}, returning empty list');
      return [];
    }
  }
  
  // Get student activities for all semesters
  Future<List<dynamic>> getStudentActivitiesBySemesters(String enrollmentNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        print('Authentication token not found for getting student activities, returning empty list');
        return [];
      }
      
      // Use the fetchEventsbyEnrollandSemester endpoint with 'all' for semester
      final response = await http.post(
        Uri.parse('$baseUrl/events/fetchEventsbyEnrollandSemester'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'enrollmentNumber': enrollmentNumber,
          'semester': 'all'
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data is List ? data : [];
      } else {
        print('Failed to get student activities: ${response.body}, returning empty list');
        return [];
      }
    } catch (e) {
      print('Error getting student activities: ${e.toString()}, returning empty list');
      return [];
    }
  }
}
