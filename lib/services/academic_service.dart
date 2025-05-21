import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

class SemesterData {
  final int semesterId;
  final int semesterNumber;
  final double spi;
  final double cpi;
  final int rank;

  SemesterData({
    required this.semesterId,
    required this.semesterNumber,
    required this.spi,
    required this.cpi,
    required this.rank,
  });

  @override
  String toString() => 'SemesterData(semester: $semesterNumber, spi: $spi, cpi: $cpi, rank: $rank)';
}

class AcademicData {
  final String enrollmentNumber;
  final int batchId;
  final Map<int, SemesterData> semesterData;
  final DateTime updatedAt;

  AcademicData({
    required this.enrollmentNumber,
    required this.batchId,
    required this.semesterData,
    required this.updatedAt,
  });

  // Get the current semester (highest semester number)
  int get currentSemester {
    if (semesterData.isEmpty) return 0;
    return semesterData.keys.reduce((a, b) => a > b ? a : b);
  }

  // Get the latest CPI (from the highest semester)
  double get latestCPI {
    if (semesterData.isEmpty) return 0.0;
    return semesterData[currentSemester]?.cpi ?? 0.0;
  }

  // Get the latest SPI (from the highest semester)
  double get latestSPI {
    if (semesterData.isEmpty) return 0.0;
    return semesterData[currentSemester]?.spi ?? 0.0;
  }

  // Get the latest rank (from the highest semester)
  int get latestRank {
    if (semesterData.isEmpty) return 0;
    return semesterData[currentSemester]?.rank ?? 0;
  }

  factory AcademicData.fromJsonList(List<dynamic> jsonList) {
    final Map<int, SemesterData> semesterMap = {};
    String enrollmentNumber = '';
    int batchId = 0;
    DateTime updatedAt = DateTime.now();

    for (var json in jsonList) {
      enrollmentNumber = json['EnrollmentNumber'] ?? '';
      batchId = json['BatchId'] ?? 0;
      updatedAt = DateTime.parse(json['updatedAt']);

      final semesterNumber = json['semesterNumber'] ?? 0;
      if (semesterNumber > 0) {  // Only add valid semester numbers
        semesterMap[semesterNumber] = SemesterData(
          semesterId: json['SemesterId'] ?? 0,
          semesterNumber: semesterNumber,
          spi: double.tryParse(json['SPI']?.toString() ?? '0') ?? 0.0,
          cpi: double.tryParse(json['CPI']?.toString() ?? '0') ?? 0.0,
          rank: int.tryParse(json['Rank']?.toString() ?? '0') ?? 0,
        );
      }
    }

    return AcademicData(
      enrollmentNumber: enrollmentNumber,
      batchId: batchId,
      semesterData: semesterMap,
      updatedAt: updatedAt,
    );
  }

  @override
  String toString() => 'AcademicData(enrollment: $enrollmentNumber, currentSemester: $currentSemester, semesters: ${semesterData.length})';
}

class SemesterSPI {
  final int semester;
  final double spi;

  SemesterSPI({required this.semester, required this.spi});

  factory SemesterSPI.fromJson(Map<String, dynamic> json) {
    return SemesterSPI(
      semester: json['semester'],
      spi: double.parse(json['spi'].toString()),
    );
  }
}

class AcademicService {
  // Dynamic base URL that works for both web and mobile platforms
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5001/api/studentCPI';
    } else if (Platform.isAndroid) {
      // Android emulator needs special IP to access host machine
      return 'http://10.0.2.2:5001/api/studentCPI';
    } else {
      // iOS and other platforms
      return 'http://localhost:5001/api/studentCPI';
    }
  }

  Future<List<SemesterSPI>> getStudentSPI(String email) async {
    try {
      final encodedEmail = Uri.encodeComponent(email);
      final endpoint = kIsWeb 
        ? 'http://localhost:5001/api/studentCPI/spi/$encodedEmail'
        : Platform.isAndroid 
          ? 'http://10.0.2.2:5001/api/studentCPI/spi/$encodedEmail'
          : 'http://localhost:5001/api/studentCPI/spi/$encodedEmail';
      
      debugPrint('Fetching SPI data from: $endpoint');
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return (jsonData['data'] as List)
              .map((item) => SemesterSPI.fromJson(item))
              .toList();
        }
      }
      
      // Return empty list instead of throwing an exception when no data is found
      print('No SPI data found for $email, returning empty list');
      return [];
    } catch (e) {
      print('Error fetching SPI data: $e');
      // Return empty list instead of throwing an exception
      return [];
    }
  }

  Future<AcademicData> getAcademicDataByEmail(String email) async {
    try {
      debugPrint('Fetching academic data for email: $email');
      final response = await http.get(
        Uri.parse('$baseUrl/email/$email'),
        headers: {'Accept': 'application/json'},
      );
      
      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final result = AcademicData.fromJsonList(data);
          debugPrint('Parsed academic data: $result');
          debugPrint('Academic data updated for enrollment: ${result.enrollmentNumber}');
          return result;
        }
        // Return a default AcademicData object if no data is found
        debugPrint('No academic data found for $email, returning default values');
        return AcademicData(
          enrollmentNumber: email.split('@')[0],
          batchId: 0,
          semesterData: {},
          updatedAt: DateTime.now(),
        );
      } else {
        // Log the error but return default values instead of throwing an exception
        final error = 'Failed to fetch academic data: ${response.statusCode}\nBody: ${response.body}';
        debugPrint(error);
        return AcademicData(
          enrollmentNumber: email.split('@')[0],
          batchId: 0,
          semesterData: {},
          updatedAt: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('Error fetching academic data: $e');
      // Return default values instead of rethrowing the exception
      return AcademicData(
        enrollmentNumber: email.split('@')[0],
        batchId: 0,
        semesterData: {},
        updatedAt: DateTime.now(),
      );
    }
  }
  
  // Get student SPI data by enrollment number
  Future<List<Map<String, dynamic>>> getSemesterSPIByEnrollment(String enrollmentNumber) async {
    try {
      final encodedEnrollment = Uri.encodeComponent(enrollmentNumber);
      final endpoint = 'http://localhost:5001/api/studentCPI/enrollment/$encodedEnrollment';
      
      debugPrint('Fetching semester SPI data from: $endpoint');
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        debugPrint('Response data: $jsonData');
        
        if (jsonData is List) {
          return jsonData.map((item) => {
            'semester': item['SemesterId'] ?? 0,
            'spi': item['SPI'] ?? 0.0,
            'cpi': item['CPI'] ?? 0.0,
            'rank': item['Rank'] ?? 0,
          }).toList();
        } else if (jsonData is Map) {
          return [{
            'semester': jsonData['SemesterId'] ?? 0,
            'spi': jsonData['SPI'] ?? 0.0,
            'cpi': jsonData['CPI'] ?? 0.0,
            'rank': jsonData['Rank'] ?? 0,
          }];
        }
      }
      
      // Return empty list if no data or error
      debugPrint('No semester SPI data found for $enrollmentNumber, returning empty list');
      return [];
    } catch (e) {
      debugPrint('Error fetching semester SPI data: $e');
      return [];
    }
  }
}
