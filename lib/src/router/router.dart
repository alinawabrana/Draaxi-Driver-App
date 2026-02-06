import 'package:flutter/material.dart';

class ARouter {
  // Keys
  static final GlobalKey<NavigatorState> rootKey = GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> shellKey = GlobalKey<NavigatorState>();

  static const String onboarding = 'onBoarding';

  //Authentication
  static const String welcome = 'welcome';
  static const String signUp = 'signUp';
  static const String signIn = 'signIn';
  static const String signinOtpVerification = 'signinOtpVerification';
  static const String signupOtpVerification = 'signupOtpVerification';
  static const String forgotPasswordOtpVerification =
      'forgotPasswordOtpVerification';
  static const String setPassword = 'setPassword';
  static const String setNewPassword = 'setNewPassword';
  static const String sendVerification = 'sendVerification';
  static const String forgotPassword = 'forgotPassword';

  // Bottom Navigation
  static const String home = 'home';
  static const String wallet = 'wallet';
  static const String chat = 'chat';
  static const String profile = 'profile';
  static const String editProfile = 'editProfile';
  static const String documentUpload = 'documentUpload';
}
