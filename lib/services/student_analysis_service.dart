import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';

class StudentAnalysisService {
  
  /// Get subject-wise performance for a student
  Future<Map<String, dynamic>> getSubjectWisePerformance(String enrollmentNumber, int semesterNumber) async {
    try {
      final url = ApiConfig.getUrl('student-analysis/performance/$enrollmentNumber/$semesterNumber');
      print('Fetching subject performance from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to fetch subject performance: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getSubjectWisePerformance: $e');
      throw Exception('Error fetching subject performance: $e');
    }
  }

  /// Get Bloom's taxonomy distribution for a student
  Future<Map<String, dynamic>> getBloomsTaxonomyDistribution(String enrollmentNumber, int semesterNumber) async {
    try {
      final url = ApiConfig.getUrl('student-analysis/blooms/$enrollmentNumber/$semesterNumber');
      print('Fetching Bloom\'s taxonomy from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to fetch Bloom\'s taxonomy: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getBloomsTaxonomyDistribution: $e');
      throw Exception('Error fetching Bloom\'s taxonomy: $e');
    }
  }

  /// Get comprehensive student analysis data
  Future<Map<String, dynamic>> getStudentAnalysisData(String enrollmentNumber) async {
    try {
      final url = ApiConfig.getUrl('student-analysis/$enrollmentNumber');
      print('Fetching student analysis from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to fetch student analysis: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getStudentAnalysisData: $e');
      throw Exception('Error fetching student analysis: $e');
    }
  }
}
