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

  // Get all students for rankings with academic data
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
        final students = json.decode(response.body) as List<dynamic>;
        
        // Fetch academic data for each student
        final enrichedStudents = <Map<String, dynamic>>[];
        
        for (var student in students) {
          final studentMap = Map<String, dynamic>.from(student);
          final email = studentMap['email'];
          
          if (email != null && email.toString().isNotEmpty) {
            try {
              // Get academic data for this student
              final academicData = await getStudentAcademicDataByEmail(email);
              if (academicData['cpiData'] != null) {
                studentMap['cpi'] = academicData['cpiData']['latestCPI'];
                studentMap['spi'] = academicData['cpiData']['latestSPI'];
                studentMap['rank'] = academicData['cpiData']['rank'];
                studentMap['currentSemester'] = academicData['cpiData']['semesterNumber'];
              }
            } catch (e) {
              print('Error fetching academic data for student $email: $e');
              // Keep student data without academic info
            }
          }
          
          enrichedStudents.add(studentMap);
        }
        
        return enrichedStudents;
      } else {
        print('Failed to get all students: ${response.body}, returning empty list');
        return [];
      }
    } catch (e) {
      print('Error getting all students: ${e.toString()}, returning empty list');
      return [];
    }
  }

  // Fetch event details from event master table
  Future<Map<String, dynamic>?> _fetchEventDetails(String eventId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/events/getEventById/$eventId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Error fetching event details for ID $eventId: $e');
    }
    return null;
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
            
            // Calculate totals and collect event details using the same approach as activities screen
            int totalCocurricular = 0;
            int totalExtracurricular = 0;
            List<Map<String, dynamic>> eventDetails = [];
            
            if (data is List && data.isNotEmpty) {
              // Extract event IDs from the response (same as StudentAnalysis.jsx)
              Set<String> eventIds = {};
              
              for (var item in data) {
                totalCocurricular += int.parse(item['totalCocurricular']?.toString() ?? '0');
                totalExtracurricular += int.parse(item['totalExtracurricular']?.toString() ?? '0');
                
                // Extract event IDs (CSV format)
                if (item['eventId'] != null) {
                  final ids = item['eventId'].toString().split(',').map((id) => id.trim()).where((id) => id.isNotEmpty);
                  eventIds.addAll(ids);
                }
              }
              
              if (eventIds.isNotEmpty) {
                // Convert to comma-separated string as required by the API
                final eventIdsString = eventIds.join(',');
                
                // Fetch event details from EventMaster table
                try {
                  final eventDetailsResponse = await http.post(
                    Uri.parse('$baseUrl/events/fetchEventsByIds'),
                    headers: {
                      'Content-Type': 'application/json',
                      'Authorization': 'Bearer $token',
                    },
                    body: json.encode({
                      'eventIds': eventIdsString
                    }),
                  );
                  
                  if (eventDetailsResponse.statusCode == 200) {
                    final eventDetailsData = json.decode(eventDetailsResponse.body);
                    
                    if (eventDetailsData['success'] == true && eventDetailsData['data'] is List) {
                      // Process event details
                      for (var event in eventDetailsData['data']) {
                        // Handle different field names for points
                        final eventType = (event['eventType'] ?? event['Event_Type'] ?? 'unknown').toString().toLowerCase();
                        int eventCocurricularPoints = 0;
                        int eventExtracurricularPoints = 0;
                        
                        // Determine points based on event type
                        if (eventType.contains('co-curricular') || eventType.contains('cocurricular')) {
                          eventCocurricularPoints = int.parse(event['cocurricularPoints']?.toString() ?? event['points']?.toString() ?? '0');
                        } else if (eventType.contains('extra-curricular') || eventType.contains('extracurricular')) {
                          eventExtracurricularPoints = int.parse(event['extracurricularPoints']?.toString() ?? event['points']?.toString() ?? '0');
                        } else {
                          // If type is unclear, try to get both
                          eventCocurricularPoints = int.parse(event['cocurricularPoints']?.toString() ?? '0');
                          eventExtracurricularPoints = int.parse(event['extracurricularPoints']?.toString() ?? '0');
                          
                          // If both are 0, use general points field
                          if (eventCocurricularPoints == 0 && eventExtracurricularPoints == 0) {
                            final generalPoints = int.parse(event['points']?.toString() ?? '0');
                            if (eventType.contains('co') || eventType.contains('technical') || eventType.contains('academic')) {
                              eventCocurricularPoints = generalPoints;
                            } else {
                              eventExtracurricularPoints = generalPoints;
                            }
                          }
                        }
                        
                        eventDetails.add({
                          'eventId': event['id'].toString(),
                          'eventName': event['eventName'] ?? event['Event_Name'] ?? 'Unknown Event',
                          'eventType': event['eventType'] ?? event['Event_Type'] ?? 'unknown',
                          'eventDate': event['eventDate'] ?? event['Event_Date'],
                          'participationType': event['participationType'] ?? event['position'] ?? 'Participant',
                          'cocurricularPoints': eventCocurricularPoints,
                          'extracurricularPoints': eventExtracurricularPoints,
                          'semester': semester,
                        });
                      }
                    }
                  }
                } catch (e) {
                  print('Error fetching event details for rankings: $e');
                }
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
              'eventDetails': eventDetails,
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
  
  // Get student activities for all semesters using studentpoints table
  Future<List<dynamic>> getStudentActivitiesBySemesters(String enrollmentNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        print('Authentication token not found for getting student activities, returning empty list');
        return [];
      }
      
      try {
        // First try to get student points data with CSV event IDs
        final studentPointsResponse = await http.post(
          Uri.parse('$baseUrl/events/getStudentPointsWithEvents'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({
            'enrollmentNumber': enrollmentNumber,
          }),
        );
        
        if (studentPointsResponse.statusCode == 200) {
          final studentPointsData = json.decode(studentPointsResponse.body);
          List<dynamic> enrichedActivities = [];
          
          if (studentPointsData is List) {
            for (var semesterData in studentPointsData) {
              final eventIds = semesterData['eventIds']?.toString() ?? '';
              final semester = semesterData['semester'];
              final cocurricularPoints = semesterData['cocurricularPoints'] ?? 0;
              final extracurricularPoints = semesterData['extracurricularPoints'] ?? 0;
              
              if (eventIds.isNotEmpty) {
                // Parse CSV event IDs
                final eventIdList = eventIds.split(',').map((id) => id.trim()).where((id) => id.isNotEmpty).toList();
                
                // Fetch details for each event ID
                for (String eventId in eventIdList) {
                  final eventDetails = await _fetchEventDetails(eventId, token);
                  
                  if (eventDetails != null) {
                    enrichedActivities.add({
                      'id': eventId,
                      'eventId': eventId,
                      'eventName': eventDetails['eventName'] ?? eventDetails['Event_Name'] ?? 'Unknown Event',
                      'eventType': eventDetails['eventType'] ?? eventDetails['Event_Type'] ?? 'unknown',
                      'eventDate': eventDetails['eventDate'] ?? eventDetails['Event_Date'],
                      'description': eventDetails['description'] ?? eventDetails['Description'],
                      'semester': semester,
                      'totalCocurricular': cocurricularPoints,
                      'totalExtracurricular': extracurricularPoints,
                      'participationType': 'Participant', // Default since we don't have this in points table
                    });
                  }
                }
              }
            }
          }
          
          return enrichedActivities;
        }
      } catch (e) {
        print('Error fetching student points data: $e');
      }
      
      // Fallback to old method
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
