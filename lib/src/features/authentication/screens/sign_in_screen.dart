import 'package:draaxi_driver/src/features/authentication/screens/sign_up_screen.dart';
import 'package:flutter/material.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key, this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    String? message;
    if (error == 'driver_only') {
      message = 'Only driver accounts can login in this app.';
    }
    return SignUpScreen(initialMode: AuthMode.signIn, initialMessage: message);
  }
}
