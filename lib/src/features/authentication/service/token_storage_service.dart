import 'package:shared_preferences/shared_preferences.dart';

class TokenStorageService {
  static const String _tokenKey = 'auth_token';
  static const String _resetTokenKey = 'reset_token';
  static const String _documentsUploadedKey = 'documents_uploaded_v3';

  /// Save authentication token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Get authentication token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Remove authentication token
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_documentsUploadedKey);
  }

  /// Check if token exists
  static Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey);
  }

  static Future<void> saveDocumentsUploaded(bool uploaded) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_documentsUploadedKey, uploaded);
  }

  static Future<bool?> getDocumentsUploaded() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_documentsUploadedKey)) return null;
    return prefs.getBool(_documentsUploadedKey);
  }

  static Future<void> removeDocumentsUploaded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_documentsUploadedKey);
  }

  /// Save reset token (for forgot password flow)
  static Future<void> saveResetToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_resetTokenKey, token);
  }

  /// Get reset token (for forgot password flow)
  static Future<String?> getResetToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_resetTokenKey);
  }

  /// Remove reset token
  static Future<void> removeResetToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_resetTokenKey);
  }

  /// Check if reset token exists
  static Future<bool> hasResetToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_resetTokenKey);
  }
}
