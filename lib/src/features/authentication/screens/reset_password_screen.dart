import 'package:draaxi_driver/src/common/widgets/password_form_field.dart';
import 'package:draaxi_driver/src/common/widgets/primary_button.dart';
import 'package:draaxi_driver/src/features/authentication/service/auth_service.dart';
import 'package:draaxi_driver/src/router/router.dart';
import 'package:draaxi_driver/utils/constant/images.dart';
import 'package:draaxi_driver/utils/helpers/helper_function.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  final AuthService _authService = AuthService();
  static const Color _primaryColor = Color(0xFFFEC400);

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await _authService.resetPassword(
          password: _newPasswordController.text,
          passwordConfirmation: _confirmPasswordController.text,
        );

        setState(() {
          _isLoading = false;
        });

        if (result['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Password reset successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            // Navigate to login screen after successful password reset
            context.goNamed(ARouter.signIn);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AHelperFunction.extractErrorMessage(result, defaultMessage: 'Password reset failed. Please try again.')),
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
              _ResetPasswordHeader(height: size.height * 0.32),
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
                            'Reset Password',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter your new password below.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: onSurface.withValues(alpha: 0.65),
                            ),
                          ),
                          const SizedBox(height: 32),
                          PasswordFormField(
                            controller: _newPasswordController,
                            textInputAction: TextInputAction.next,
                            hintText: 'New Password',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your new password';
                              }
                              if (value.trim().length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          PasswordFormField(
                            controller: _confirmPasswordController,
                            textInputAction: TextInputAction.done,
                            hintText: 'Confirm New Password',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please confirm your new password';
                              }
                              if (value != _newPasswordController.text) {
                                return 'Passwords do not match';
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
                              text: 'Set Password',
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

class _ResetPasswordHeader extends StatelessWidget {
  const _ResetPasswordHeader({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: _ResetPasswordScreenState._primaryColor),
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
