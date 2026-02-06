import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:draaxi_driver/src/features/authentication/service/token_storage_service.dart';

class AuthService {
  static const String baseUrl = 'https://draaxi.com/api';

  Map<String, dynamic> _failureResponse(
    Map<String, dynamic> responseData, {
    required String fallbackMessage,
  }) {
    final dynamic rawError = responseData['error'];
    final dynamic rawErrors = responseData['errors'];

    final dynamic normalizedErrors =
        rawErrors ?? ((rawError is Map || rawError is List) ? rawError : null);

    final String? normalizedError = (responseData['message'] is String &&
            (responseData['message'] as String).isNotEmpty)
        ? responseData['message'] as String
        : (rawError is String && rawError.isNotEmpty)
            ? rawError
            : null;

    return {
      'success': false,
      'error': normalizedError ?? fallbackMessage,
      'errors': normalizedErrors,
      'message': responseData['message'],
    };
  }

  void _logRequest(String method, Uri url, Map<String, String> headers, Map<String, dynamic> body) {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📤 API REQUEST');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('Method: $method');
    debugPrint('URL: $url');
    debugPrint('Headers: ${headers.toString()}');
    
    // Mask sensitive fields in request body
    final maskedBody = Map<String, dynamic>.from(body);
    if (maskedBody.containsKey('password')) {
      maskedBody['password'] = '***';
    }
    if (maskedBody.containsKey('password_confirmation')) {
      maskedBody['password_confirmation'] = '***';
    }
    if (maskedBody.containsKey('otp')) {
      maskedBody['otp'] = '***';
    }
    if (maskedBody.containsKey('token')) {
      maskedBody['token'] = '***';
    }
    if (maskedBody.containsKey('reset_token')) {
      maskedBody['reset_token'] = '***';
    }
    
    debugPrint('Body: ${jsonEncode(maskedBody)}');
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

  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String phone,
    required String countryCode,
    required String gender,
    required String password,
    required String passwordConfirmation,
    required String role,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/signup');
      
      final requestBody = {
        'name': name,
        'email': email,
        'phone': phone,
        'country_code': countryCode,
        'gender': gender,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'role': role,
      };
      
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      _logRequest('POST', url, headers, requestBody);
      
      final response = await http.post(
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
        return _failureResponse(responseData, fallbackMessage: 'Signup failed');
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> verifySignupOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/verify-signup-otp');
      
      // Get saved token from signup
      final token = await TokenStorageService.getToken();
      debugPrint('🔑 Retrieving token for OTP verification: ${token != null ? (token.isNotEmpty ? "Token found (length: ${token.length})" : "Token is empty") : "Token is null"}');
      
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      // Add Authorization header if token exists
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        debugPrint('✅ Authorization header added with token: ${token.substring(0, token.length > 10 ? 10 : token.length)}... (length: ${token.length})');
        debugPrint('🔐 Full Authorization header: Bearer $token');
      } else {
        debugPrint('❌ No token available, proceeding without Authorization header');
      }
      
      final Map<String, dynamic> requestBody = {
        'email': email,
        'otp': otp,
      };
      
      // Add token to request body (API requires token in body for signup OTP verification)
      if (token != null && token.isNotEmpty) {
        requestBody['token'] = token;
        debugPrint('✅ Token added to request body');
      }
      
      _logRequest('POST', url, headers, requestBody);
      
      final response = await http.post(
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
        return _failureResponse(
          responseData,
          fallbackMessage: 'OTP verification failed',
        );
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/login');
      
      final requestBody = {
        'identifier': identifier,
        'password': password,
      };
      
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      _logRequest('POST', url, headers, requestBody);
      
      final response = await http.post(
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
        return _failureResponse(responseData, fallbackMessage: 'Login failed');
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> sendForgotOtp({
    required String email,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/send-forgot-otp');
      
      final requestBody = {
        'email': email,
      };
      
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      _logRequest('POST', url, headers, requestBody);
      
      final response = await http.post(
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
        return _failureResponse(
          responseData,
          fallbackMessage: 'Failed to send OTP',
        );
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> verifyForgotOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/verify-forgot-otp');
      
      // Get saved reset token from send-forgot-otp
      final token = await TokenStorageService.getResetToken();
      debugPrint('🔑 Retrieving reset token for forgot password OTP verification: ${token != null ? (token.isNotEmpty ? "Token found (length: ${token.length})" : "Token is empty") : "Token is null"}');
      
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      // Add Authorization header if token exists
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        debugPrint('✅ Authorization header added with reset token: ${token.substring(0, token.length > 10 ? 10 : token.length)}... (length: ${token.length})');
      } else {
        debugPrint('❌ No reset token available, proceeding without Authorization header');
      }
      
      final Map<String, dynamic> requestBody = {
        'email': email,
        'otp': otp,
      };
      
      // Add reset_token to request body (API requires reset_token in body for forgot password OTP verification)
      if (token != null && token.isNotEmpty) {
        requestBody['reset_token'] = token;
        debugPrint('✅ Reset token added to request body');
      }
      
      _logRequest('POST', url, headers, requestBody);
      
      final response = await http.post(
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
        return _failureResponse(
          responseData,
          fallbackMessage: 'OTP verification failed',
        );
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/reset-password');
      
      // Get saved reset token
      final resetToken = await TokenStorageService.getResetToken();
      
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      // Add Authorization header if token exists
      if (resetToken != null && resetToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $resetToken';
      }
      
      final Map<String, dynamic> requestBody = {
        'password': password,
        'password_confirmation': passwordConfirmation,
      };
      
      // Add reset_token to request body if it exists
      if (resetToken != null && resetToken.isNotEmpty) {
        requestBody['reset_token'] = resetToken;
      }
      
      _logRequest('POST', url, headers, requestBody);
      
      final response = await http.post(
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
        return _failureResponse(
          responseData,
          fallbackMessage: 'Password reset failed',
        );
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      final url = Uri.parse('$baseUrl/logout');
      
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
      
      _logRequest('POST', url, headers, {});
      
      final response = await http.post(
        url,
        headers: headers,
      );

      _logResponse(response.statusCode, response.headers, response.body);

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Remove token from storage after successful logout
        await TokenStorageService.removeToken();
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return _failureResponse(responseData, fallbackMessage: 'Logout failed');
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }
}
