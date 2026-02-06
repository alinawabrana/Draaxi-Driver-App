import 'package:flutter/material.dart';

@immutable
class AImages {
  const AImages._();

  // Onboarding images (place these files under assets/onboardings/)
  static const String requestRide = 'assets/onboardings/Request Ride.png';
  static const String confirmYourClient =
      'assets/onboardings/Confirm your Client.png';
  static const String trackYourDestination =
      'assets/onboardings/Track your Destination.png';

  // Welcome screen image
  static const String welcomeScreen = 'assets/images/Welcome Screen.png';
  static const String signUpHeader = 'assets/images/Sign up image.png';

  // Social login images
  static const String gmail = 'assets/logo/Gmail.png';
  static const String facebook = 'assets/logo/Facebook.png';
  static const String apple = 'assets/logo/Apple.png';
}
