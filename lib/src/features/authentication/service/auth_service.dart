import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:draaxi_driver/src/features/authentication/service/token_storage_service.dart';

class AuthService {
  static const String baseUrl = 'https://draaxi.com/api';
  static const Duration _requestTimeout = Duration(seconds: 25);

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

  Map<String, String> _normalizeHeaders(Map<String, String> headers) {
    final normalized = Map<String, String>.from(headers);

    normalized.putIfAbsent('Accept', () => 'application/json');
    normalized.putIfAbsent('Content-Type', () => 'application/json');
    normalized.putIfAbsent('User-Agent', () => 'draaxi_driver_flutter');

    return normalized;
  }

  Future<Map<String, dynamic>> _postJson(
    Uri url, {
    required Map<String, String> headers,
    Map<String, dynamic>? requestBody,
    required String fallbackMessage,
  }) async {
    final normalizedHeaders = _normalizeHeaders(headers);
    final bodyForLog = requestBody ?? <String, dynamic>{};
    _logRequest('POST', url, normalizedHeaders, bodyForLog);

    try {
      final response = await http
          .post(
            url,
            headers: normalizedHeaders,
            body: requestBody == null ? null : jsonEncode(requestBody),
          )
          .timeout(_requestTimeout);

      _logResponse(response.statusCode, response.headers, response.body);

      Map<String, dynamic>? responseData;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          responseData = decoded;
        } else if (decoded is List) {
          responseData = <String, dynamic>{'data': decoded};
        }
      } catch (_) {
        responseData = null;
      }

      if (responseData == null) {
        final bodySnippet = response.body.length > 300
            ? response.body.substring(0, 300)
            : response.body;
        return {
          'success': false,
          'error': 'Unexpected server response (${response.statusCode})',
          'body': bodySnippet,
          'statusCode': response.statusCode,
        };
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': responseData,
          'statusCode': response.statusCode,
        };
      }

      final failure =
          _failureResponse(responseData, fallbackMessage: fallbackMessage);
      failure['statusCode'] = response.statusCode;
      return failure;
    } on TimeoutException {
      return {
        'success': false,
        'error': 'Request timed out. Please try again.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
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

    return _postJson(
      url,
      headers: const {},
      requestBody: requestBody,
      fallbackMessage: 'Signup failed',
    );
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
      
      return _postJson(
        url,
        headers: headers,
        requestBody: requestBody,
        fallbackMessage: 'OTP verification failed',
      );
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
    final url = Uri.parse('$baseUrl/auth/login');

    final requestBody = {
      'identifier': identifier,
      'password': password,
    };

    return _postJson(
      url,
      headers: const {},
      requestBody: requestBody,
      fallbackMessage: 'Login failed',
    );
  }

  Future<Map<String, dynamic>> sendForgotOtp({
    required String email,
  }) async {
    final url = Uri.parse('$baseUrl/auth/send-forgot-otp');

    final requestBody = {
      'email': email,
    };

    return _postJson(
      url,
      headers: const {},
      requestBody: requestBody,
      fallbackMessage: 'Failed to send OTP',
    );
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
      
      return _postJson(
        url,
        headers: headers,
        requestBody: requestBody,
        fallbackMessage: 'OTP verification failed',
      );
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
      
      return _postJson(
        url,
        headers: headers,
        requestBody: requestBody,
        fallbackMessage: 'Password reset failed',
      );
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

      final token = await TokenStorageService.getToken();

      final Map<String, String> headers = {};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final result = await _postJson(
        url,
        headers: headers,
        requestBody: null,
        fallbackMessage: 'Logout failed',
      );

      if (result['success'] == true) {
        await TokenStorageService.removeToken();
      }

      return result;
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }
}
