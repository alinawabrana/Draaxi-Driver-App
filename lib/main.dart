import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    final platform = GoogleMapsFlutterPlatform.instance;
    if (platform is GoogleMapsFlutterAndroid) {
      platform.useAndroidViewSurface = true;
    }
  }
  runApp(const MyApp());
}
