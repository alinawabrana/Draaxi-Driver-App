import 'dart:async';
import 'dart:convert';

import 'package:draaxi_driver/src/features/authentication/service/token_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DriverApiService {
  static const String baseUrl = 'https://draaxi.com/api';
  static const Duration _requestTimeout = Duration(seconds: 25);

  void _logRequest(
    String method,
    Uri url,
    Map<String, String> headers,
    Map<String, dynamic>? body,
  ) {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📤 DRIVER API REQUEST');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('Method: $method');
    debugPrint('URL: $url');

    final maskedHeaders = Map<String, String>.from(headers);
    final auth = maskedHeaders['Authorization'];
    if (auth != null && auth.startsWith('Bearer ')) {
      final token = auth.substring(7);
      maskedHeaders['Authorization'] =
          'Bearer ${token.length > 10 ? token.substring(0, 10) : token}... (masked)';
    }
    debugPrint('Headers: $maskedHeaders');

    if (body != null) {
      debugPrint('Body: ${jsonEncode(body)}');
    }
    debugPrint('═══════════════════════════════════════════════════════');
  }

  void _logResponse(int statusCode, Map<String, String> headers, String body) {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📥 DRIVER API RESPONSE');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('Status Code: $statusCode');
    debugPrint('Headers: $headers');
    debugPrint('Body: $body');
    debugPrint('═══════════════════════════════════════════════════════');
  }

  Future<Map<String, String>> _headers() async {
    final token = await TokenStorageService.getToken();
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Map<String, dynamic> _decodeBody(String body, int statusCode) {
    if (body.trim().isEmpty) {
      return <String, dynamic>{'statusCode': statusCode};
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is List) {
        return <String, dynamic>{'data': decoded, 'statusCode': statusCode};
      }
    } catch (_) {}

    return <String, dynamic>{'raw': body, 'statusCode': statusCode};
  }

  Map<String, dynamic> _resultFromResponse(http.Response response) {
    final payload = _decodeBody(response.body, response.statusCode);
    final ok = response.statusCode >= 200 && response.statusCode < 300;

    return <String, dynamic>{
      'success': ok,
      'statusCode': response.statusCode,
      if (ok) 'data': payload,
      if (!ok)
        'error':
            payload['message'] ??
            payload['error'] ??
            'Request failed (${response.statusCode})',
      if (!ok) 'errors': payload['errors'],
      'payload': payload,
    };
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final url = Uri.parse('$baseUrl$path');
    try {
      final headers = await _headers();
      _logRequest('GET', url, headers, null);
      final response = await http
          .get(url, headers: headers)
          .timeout(_requestTimeout);
      _logResponse(response.statusCode, response.headers, response.body);
      return _resultFromResponse(response);
    } on TimeoutException {
      return <String, dynamic>{
        'success': false,
        'error': 'Request timed out. Please try again.',
      };
    } catch (e) {
      return <String, dynamic>{
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('$baseUrl$path');
    try {
      final headers = await _headers();
      _logRequest('POST', url, headers, body);
      final response = await http
          .post(
            url,
            headers: headers,
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(_requestTimeout);
      _logResponse(response.statusCode, response.headers, response.body);
      return _resultFromResponse(response);
    } on TimeoutException {
      return <String, dynamic>{
        'success': false,
        'error': 'Request timed out. Please try again.',
      };
    } catch (e) {
      return <String, dynamic>{
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getDriverStatus() {
    return _get('/driver/status');
  }

  Future<Map<String, dynamic>> setDriverStatus({
    required bool isOnline,
    bool? isAvailable,
    double? lat,
    double? lng,
  }) {
    final payload = <String, dynamic>{'is_online': isOnline};
    if (isAvailable != null) payload['is_available'] = isAvailable;
    if (lat != null) {
      payload['lat'] = lat;
      payload['latitude'] = lat;
    }
    if (lng != null) {
      payload['lng'] = lng;
      payload['longitude'] = lng;
    }
    return _post('/driver/status', body: payload);
  }

  Future<Map<String, dynamic>> updateDriverLocation({
    required double lat,
    required double lng,
    double? heading,
    double? speed,
  }) {
    final payload = <String, dynamic>{'lat': lat, 'lng': lng};
    if (heading != null) payload['heading'] = heading;
    if (speed != null) payload['speed'] = speed;
    return _post('/driver/location', body: payload);
  }

  Future<Map<String, dynamic>> getPendingRequests() {
    return _get('/driver/requests/pending');
  }

  Future<Map<String, dynamic>> acceptRequest(String requestId) {
    return _post('/driver/requests/$requestId/accept');
  }

  Future<Map<String, dynamic>> declineRequest(String requestId) {
    return _post('/driver/requests/$requestId/decline');
  }

  Future<Map<String, dynamic>> offerFare(String requestId, double fare) {
    return _post(
      '/driver/requests/$requestId/offer-fare',
      body: {'fare': fare},
    );
  }

  Future<Map<String, dynamic>> getCurrentRide() {
    return _get('/driver/rides/current');
  }

  Future<Map<String, dynamic>> markReachedPickup(String rideId) {
    return _post('/driver/rides/$rideId/start');
  }

  Future<Map<String, dynamic>> beginTrip(String rideId) {
    return _post('/driver/rides/$rideId/begin-trip');
  }

  Future<Map<String, dynamic>> completeRide(String rideId) {
    return _post('/driver/rides/$rideId/complete');
  }

  Future<Map<String, dynamic>> cancelRide(String rideId) {
    return _post('/driver/rides/$rideId/cancel');
  }
}
