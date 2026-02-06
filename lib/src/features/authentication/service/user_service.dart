import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:draaxi_driver/src/features/authentication/service/token_storage_service.dart';

class UserService {
  static const String baseUrl = 'https://draaxi.com/api';

  void _logRequest(String method, Uri url, Map<String, String> headers, Map<String, dynamic>? body) {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📤 API REQUEST');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('Method: $method');
    debugPrint('URL: $url');
    
    // Mask Authorization token in headers log
    final maskedHeaders = Map<String, String>.from(headers);
    if (maskedHeaders.containsKey('Authorization')) {
      final authHeader = maskedHeaders['Authorization']!;
      if (authHeader.startsWith('Bearer ')) {
        final token = authHeader.substring(7);
        maskedHeaders['Authorization'] = 'Bearer ${token.length > 10 ? token.substring(0, 10) : token}... (masked)';
      }
    }
    debugPrint('Headers: ${maskedHeaders.toString()}');
    
    if (body != null) {
      // Mask sensitive fields in request body
      final maskedBody = Map<String, dynamic>.from(body);
      if (maskedBody.containsKey('password')) {
        maskedBody['password'] = '***';
      }
      if (maskedBody.containsKey('password_confirmation')) {
        maskedBody['password_confirmation'] = '***';
      }
      debugPrint('Body: ${jsonEncode(maskedBody)}');
    }
    debugPrint('═══════════════════════════════════════════════════════');
  }

  void _logResponse(int statusCode, Map<String, String> headers, String body) {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📥 API RESPONSE');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('Status Code: $statusCode');
    debugPrint('Headers: ${headers.toString()}');
    debugPrint('Body: $body');
    
    // Also log formatted JSON if possible
    try {
      final jsonData = jsonDecode(body) as Map<String, dynamic>;
      debugPrint('Body (Formatted): ${jsonEncode(jsonData)}');
    } catch (e) {
      // Body is not JSON, already logged above
    }
    debugPrint('═══════════════════════════════════════════════════════');
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final url = Uri.parse('$baseUrl/user');
      
      // Get saved token
      final token = await TokenStorageService.getToken();
      debugPrint('🔑 Retrieved token for /user API: ${token != null ? (token.isNotEmpty ? "Token exists (length: ${token.length})" : "Token is empty") : "Token is NULL"}');
      
      if (token != null && token.isNotEmpty) {
        debugPrint('🔐 Token preview: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
        debugPrint('🔐 Full Authorization header: Bearer $token');
      } else {
        debugPrint('❌ WARNING: No token found in storage! This will cause 401 Unauthenticated error.');
      }
      
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      // Add Authorization header if token exists
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        debugPrint('✅ Authorization header added to request');
      } else {
        debugPrint('❌ Authorization header NOT added - token is missing!');
      }
      
      _logRequest('GET', url, headers, null);
      
      final response = await http.get(
        url,
        headers: headers,
      );

      _logResponse(response.statusCode, response.headers, response.body);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      // Log authentication status
      if (response.statusCode == 401) {
        debugPrint('❌ 401 Unauthenticated Error - Token might be missing, invalid, or expired');
        debugPrint('🔍 Checking stored token...');
        final storedToken = await TokenStorageService.getToken();
        if (storedToken == null || storedToken.isEmpty) {
          debugPrint('❌ CRITICAL: No token found in storage! User needs to login again.');
        } else {
          debugPrint('⚠️ Token exists in storage but API rejected it. Token might be expired or invalid.');
          debugPrint('🔐 Stored token preview: ${storedToken.substring(0, storedToken.length > 20 ? 20 : storedToken.length)}...');
        }
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'error': responseData['message'] ?? responseData['error'] ?? 'Failed to fetch profile',
          'errors': responseData['errors'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/profile');
      
      // Get saved token
      final token = await TokenStorageService.getToken();
      
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      // Add Authorization header if token exists
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final requestBody = {
        'name': name,
        'email': email,
        'phone': phone,
      };
      
      _logRequest('PUT', url, headers, requestBody);
      
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      _logResponse(response.statusCode, response.headers, response.body);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'error': responseData['message'] ?? responseData['error'] ?? 'Failed to update profile',
          'errors': responseData['errors'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> updateDriverProfile({
    required String name,
    required String email,
    required String phone,
    String? city,
    String? district,
    String? vehicleType,
    String? vehicleNo,
    String? vehicleDescription,
    String? licenseNo,
    File? profileImage,
    File? vehicleDoc,
    File? licenseDoc,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/profile');
      
      // Get saved token
      final token = await TokenStorageService.getToken();
      
      // Create multipart request for file uploads
      // API supports POST method only
      final request = http.MultipartRequest('POST', url);
      
      // Add headers
      request.headers['Accept'] = 'application/json';
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      // Add text fields
      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['phone'] = phone;
      if (city != null && city.isNotEmpty) {
        request.fields['city'] = city;
      }
      if (district != null && district.isNotEmpty) {
        request.fields['district'] = district;
      }
      if (vehicleType != null && vehicleType.isNotEmpty) {
        request.fields['vehicle_type'] = vehicleType;
      }
      if (vehicleNo != null && vehicleNo.isNotEmpty) {
        request.fields['vehicle_no'] = vehicleNo;
      }
      if (vehicleDescription != null && vehicleDescription.isNotEmpty) {
        request.fields['vehicle_description'] = vehicleDescription;
      }
      if (licenseNo != null && licenseNo.isNotEmpty) {
        request.fields['license_no'] = licenseNo;
      }
      
      // Add files if provided
      if (profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('profile_image', profileImage.path),
        );
      }
      if (vehicleDoc != null) {
        request.files.add(
          await http.MultipartFile.fromPath('vehicle_doc', vehicleDoc.path),
        );
      }
      if (licenseDoc != null) {
        request.files.add(
          await http.MultipartFile.fromPath('license_doc', licenseDoc.path),
        );
      }
      
      // Log request (simplified for multipart)
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('📤 API REQUEST (Multipart)');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('Method: POST');
      debugPrint('URL: $url');
      debugPrint('Fields: ${request.fields}');
      debugPrint('Files: ${request.files.map((f) => f.filename).toList()}');
      debugPrint('═══════════════════════════════════════════════════════');
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      _logResponse(response.statusCode, response.headers, response.body);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'error': responseData['message'] ?? responseData['error'] ?? 'Failed to update profile',
          'errors': responseData['errors'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }
}

