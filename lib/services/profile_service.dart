import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_config.dart';

class ProfileService {
  // Upload profile image to server (web-compatible)
  Future<Map<String, dynamic>> uploadProfileImage(String email, dynamic imageData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      String base64Image;
      String fileName;
      
      if (kIsWeb) {
        // For web: imageData is Uint8List
        if (imageData is Uint8List) {
          base64Image = base64Encode(imageData);
          fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        } else {
          throw Exception('Invalid image data for web platform');
        }
      } else {
        // For mobile: imageData is File
        if (imageData is File) {
          final bytes = await imageData.readAsBytes();
          base64Image = base64Encode(bytes);
          fileName = imageData.path.split('/').last;
        } else {
          throw Exception('Invalid image data for mobile platform');
        }
      }

      final response = await http.post(
        Uri.parse(ApiConfig.getUrl('profile/uploadImageBase64')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'email': email,
          'imageData': base64Image,
          'fileName': fileName,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading profile image: $e');
      throw Exception('Failed to upload profile image: $e');
    }
  }

  // Get profile image URL for a user
  Future<String?> getProfileImageUrl(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse(ApiConfig.getUrl('profile/getImage/$email')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['imageUrl'];
      } else if (response.statusCode == 404) {
        // No profile image found
        return null;
      } else {
        throw Exception('Failed to get profile image: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting profile image: $e');
      return null;
    }
  }

  // Delete profile image
  Future<bool> deleteProfileImage(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.delete(
        Uri.parse(ApiConfig.getUrl('profile/deleteImage')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'email': email}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting profile image: $e');
      return false;
    }
  }

  // Update user profile information
  Future<Map<String, dynamic>> updateProfile({
    required String email,
    String? name,
    String? phone,
    String? bio,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final Map<String, dynamic> updateData = {'email': email};
      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;
      if (bio != null) updateData['bio'] = bio;

      final response = await http.put(
        Uri.parse(ApiConfig.getUrl('profile/update')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }
}
