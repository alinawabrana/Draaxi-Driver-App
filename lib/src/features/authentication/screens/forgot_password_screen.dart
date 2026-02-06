import 'package:draaxi_driver/src/common/widgets/primary_button.dart';
import 'package:draaxi_driver/src/common/widgets/primary_text_form_field.dart';
import 'package:draaxi_driver/src/features/authentication/service/auth_service.dart';
import 'package:draaxi_driver/src/features/authentication/service/token_storage_service.dart';
import 'package:draaxi_driver/src/router/router.dart';
import 'package:draaxi_driver/utils/constant/images.dart';
import 'package:draaxi_driver/utils/helpers/helper_function.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  final AuthService _authService = AuthService();
  static const Color _primaryColor = Color(0xFFFEC400);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await _authService.sendForgotOtp(
          email: _emailController.text.trim(),
        );

        setState(() {
          _isLoading = false;
        });

        if (result['success'] == true) {
          // Save reset token from response
          final responseData = result['data'] as Map<String, dynamic>?;
          final resetToken = responseData?['reset_token'] as String?;
          if (resetToken != null && resetToken.isNotEmpty) {
            await TokenStorageService.saveResetToken(resetToken);
          }
          
          if (mounted) {
            context.goNamed(
              ARouter.forgotPasswordOtpVerification,
              queryParameters: {
                'email': _emailController.text.trim(),
              },
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AHelperFunction.extractErrorMessage(result, defaultMessage: 'Failed to send OTP. Please try again.')),
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
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = AHelperFunction.isDarkMode(context);
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ForgotPasswordHeader(height: size.height * 0.32),
              Transform.translate(
                offset: const Offset(0, -32),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 12),
                          ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Forgot Password',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter your email address and we will send you an OTP to reset your password.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: onSurface.withValues(alpha: 0.65),
                            ),
                          ),
                          const SizedBox(height: 32),
                          PrimaryTextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            hintText: 'name@example.com',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegex.hasMatch(value.trim())) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          Theme(
                            data: Theme.of(context).copyWith(
                              elevatedButtonTheme: ElevatedButtonThemeData(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryColor,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            child: PrimaryButton(
                              text: 'Continue',
                              onPressed: _isLoading ? () {} : () => _submit(),
                              isLoading: _isLoading,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ForgotPasswordHeader extends StatelessWidget {
  const _ForgotPasswordHeader({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: _ForgotPasswordScreenState._primaryColor),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Image.asset(
            AImages.signUpHeader,
            fit: BoxFit.cover,
            width: double.infinity,
            height: height * 0.65,
          ),
        ),
      ),
    );
  }
}
