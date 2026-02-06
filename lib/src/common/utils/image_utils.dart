class ImageUtils {
  static const String baseImageUrl = 'https://draaxi.com/storage/app/public/';

  /// Prefixes the image path with the base URL if it's not already a full URL
  static String getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }

    // If the path already starts with http:// or https://, return as is
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    // Remove leading slash if present to avoid double slashes
    final cleanPath = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;

    // Prefix with base URL
    return '$baseImageUrl$cleanPath';
  }
}

