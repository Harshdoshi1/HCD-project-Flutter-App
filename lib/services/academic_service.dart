import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

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

class AcademicService {
  static const String baseUrl = 'http://localhost:5001/api/studentCPI';

  Future<AcademicData?> getAcademicDataByEmail(String email) async {
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
          return result;
        }
        return null;
      } else {
        final error = 'Failed to fetch academic data: ${response.statusCode}\nBody: ${response.body}';
        debugPrint(error);
        throw Exception(error);
      }
    } catch (e) {
      debugPrint('Error fetching academic data: $e');
      rethrow;
    }
  }
}
