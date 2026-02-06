import 'package:draaxi_driver/src/common/widgets/primary_button.dart';
import 'package:draaxi_driver/src/features/authentication/service/auth_service.dart';
import 'package:draaxi_driver/src/features/authentication/service/token_storage_service.dart';
import 'package:draaxi_driver/src/router/router.dart';
import 'package:draaxi_driver/utils/helpers/helper_function.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

enum OtpType { signup, forgotPassword }

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.otpType = OtpType.signup,
  });

  final String email;
  final OtpType otpType;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const Color _primaryColor = Color(0xFFFEC400);
  static const int _otpLength = 4;

  final List<TextEditingController> _controllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _otpLength,
    (_) => FocusNode(),
  );

  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.length > 1) {
      _controllers[index].text = value.substring(value.length - 1);
      _controllers[index].selection = TextSelection.fromPosition(
        TextPosition(offset: _controllers[index].text.length),
      );
    }

    if (value.isNotEmpty && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  Future<void> _verify() async {
    final otp = _controllers.map((controller) => controller.text).join();
    if (otp.length != _otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get email from widget parameter
    final email = widget.email;
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email not found. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> result;
      
      if (widget.otpType == OtpType.forgotPassword) {
        // Use forgot password OTP verification
        result = await _authService.verifyForgotOtp(
          email: email,
          otp: otp,
        );
      } else {
        // Use signup OTP verification
        result = await _authService.verifySignupOtp(
          email: email,
          otp: otp,
        );
      }

      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        if (widget.otpType == OtpType.forgotPassword) {
          if (!mounted) return;
          context.goNamed(
            ARouter.setNewPassword,
            queryParameters: {
              'email': email,
            },
          );
        } else {
          await TokenStorageService.removeToken();
          if (!mounted) return;
          debugPrint('✅ Temporary signup token removed. User should log in to get authentication token.');
          context.goNamed(ARouter.signIn);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AHelperFunction.extractErrorMessage(result, defaultMessage: 'OTP verification failed. Please try again.')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: _primaryColor,
              padding: const EdgeInsets.only(
                top: 8,
                bottom: 32,
                left: 16,
                right: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Email Verification',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter the 4-digit OTP sent to your email',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 48),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(_otpLength, (index) {
                          return SizedBox(
                            width: 60,
                            child: TextField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              autofocus: index == 0,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w600,
                                color: onSurface,
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(1),
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (value) => _onChanged(value, index),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: onSurface.withValues(alpha: 0.25),
                                    width: 2,
                                  ),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: _primaryColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 56),
                      Theme(
                        data: Theme.of(context).copyWith(
                          elevatedButtonTheme: ElevatedButtonThemeData(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        child: PrimaryButton(
                          text: 'Verify Now',
                          onPressed: _isLoading ? () {} : () => _verify(),
                          isLoading: _isLoading,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
