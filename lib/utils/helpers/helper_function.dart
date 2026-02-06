import 'package:flutter/material.dart';

class AHelperFunction {
  const AHelperFunction._();

  /// Checks if the current theme is dark mode
  /// Returns true if dark mode is active, false otherwise
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Extracts error message from API response
  /// Handles both field-specific errors (errors) and general error messages (error)
  /// Returns a user-friendly error message
  static String extractErrorMessage(Map<String, dynamic> result, {String? defaultMessage}) {
    // First, check for field-specific validation errors (Laravel format)
    final errors = result['errors'];
    if (errors != null) {
      if (errors is Map<String, dynamic>) {
        // Get the first error message from the first field
        for (final fieldErrors in errors.values) {
          if (fieldErrors is List && fieldErrors.isNotEmpty) {
            return fieldErrors.first.toString();
          } else if (fieldErrors is String) {
            return fieldErrors;
          }
        }
      } else if (errors is List && errors.isNotEmpty) {
        return errors.first.toString();
      } else if (errors is String) {
        return errors;
      }
    }

    // Fall back to general error message
    final error = result['error'];
    if (error != null && error.toString().isNotEmpty) {
      return error.toString();
    }

    // Fall back to message field
    final message = result['message'];
    if (message != null && message.toString().isNotEmpty) {
      return message.toString();
    }

    // Return default message if no error found
    return defaultMessage ?? 'An error occurred. Please try again.';
  }
}
