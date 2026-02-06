import 'package:country_code_picker/country_code_picker.dart';
import 'package:draaxi_driver/src/common/widgets/dropdown_form_field.dart';
import 'package:draaxi_driver/src/common/widgets/password_form_field.dart';
import 'package:draaxi_driver/src/common/widgets/phone_form_field.dart';
import 'package:draaxi_driver/src/common/widgets/primary_button.dart';
import 'package:draaxi_driver/src/common/widgets/primary_text_form_field.dart';
import 'package:draaxi_driver/src/features/authentication/service/auth_service.dart';
import 'package:draaxi_driver/src/features/authentication/service/token_storage_service.dart';
import 'package:draaxi_driver/src/features/authentication/service/user_service.dart';
import 'package:draaxi_driver/src/router/router.dart';
import 'package:draaxi_driver/utils/constant/images.dart';
import 'package:draaxi_driver/utils/constant/texts.dart';
import 'package:draaxi_driver/utils/helpers/helper_function.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum AuthMode { signUp, signIn }

enum SignInMethod { phone, email }

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({
    super.key,
    this.initialMode = AuthMode.signUp,
    this.initialMessage,
  });

  final AuthMode initialMode;
  final String? initialMessage;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _signUpFirstNameController =
      TextEditingController();
  final TextEditingController _signUpLastNameController =
      TextEditingController();
  final TextEditingController _signUpEmailController = TextEditingController();
  final TextEditingController _signUpPhoneController = TextEditingController();
  final TextEditingController _signUpPasswordController =
      TextEditingController();
  final TextEditingController _signUpPasswordConfirmationController =
      TextEditingController();
  final TextEditingController _signInEmailController = TextEditingController();
  final TextEditingController _signInPhoneController = TextEditingController();
  final TextEditingController _signInPasswordController =
      TextEditingController();

  CountryCode _signUpCountryCode = CountryCode.fromDialCode('+92');
  CountryCode _signInCountryCode = CountryCode.fromDialCode('+92');

  String? _selectedGender;
  bool _isLoading = false;

  final AuthService _authService = AuthService();

  static const Color _primaryColor = Color(0xFFFEC400);

  late AuthMode _mode;
  SignInMethod _signInMethod = SignInMethod.phone;
  bool _didShowInitialMessage = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_didShowInitialMessage) return;
      final message = widget.initialMessage;
      if (message == null || message.isEmpty) return;
      if (!mounted) return;
      _didShowInitialMessage = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.orange),
      );
    });
  }

  @override
  void dispose() {
    _signUpFirstNameController.dispose();
    _signUpLastNameController.dispose();
    _signUpEmailController.dispose();
    _signUpPhoneController.dispose();
    _signUpPasswordController.dispose();
    _signUpPasswordConfirmationController.dispose();
    _signInEmailController.dispose();
    _signInPhoneController.dispose();
    _signInPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();

      if (_mode == AuthMode.signUp) {
        setState(() {
          _isLoading = true;
        });

        try {
          final name =
              '${_signUpFirstNameController.text.trim()} ${_signUpLastNameController.text.trim()}'
                  .trim();

          final result = await _authService.signup(
            name: name,
            email: _signUpEmailController.text.trim(),
            phone: _signUpPhoneController.text.trim(),
            countryCode: _signUpCountryCode.dialCode ?? '+92',
            gender: _selectedGender ?? '',
            password: _signUpPasswordController.text,
            passwordConfirmation: _signUpPasswordConfirmationController.text,
            role: 'driver',
          );

          setState(() {
            _isLoading = false;
          });

          if (result['success'] == true) {
            // Save token from response
            // Response structure: result['data'] = {"message":"OTP sent","token":"..."}
            final responseData = result['data'] as Map<String, dynamic>?;
            debugPrint('📋 Signup Response Data: $responseData');

            // Extract token directly from response data
            final token = responseData?['token'] as String?;
            if (token != null && token.isNotEmpty) {
              debugPrint(
                '🔑 Extracted Token: ${token.substring(0, token.length > 10 ? 10 : token.length)}... (length: ${token.length})',
              );
              await TokenStorageService.saveToken(token);
              debugPrint('✅ Token saved to storage successfully');

              // Verify token was saved by retrieving it
              final savedToken = await TokenStorageService.getToken();
              if (savedToken == token) {
                debugPrint(
                  '✅ Token verification: Saved token matches extracted token',
                );
              } else {
                debugPrint(
                  '❌ Token verification failed: Saved token does not match',
                );
              }
            } else {
              debugPrint(
                '❌ Token not found in response. Available keys: ${responseData?.keys.toList()}',
              );
              debugPrint('❌ Full responseData: $responseData');
            }

            if (mounted) {
              context.goNamed(
                ARouter.signupOtpVerification,
                queryParameters: {'email': _signUpEmailController.text.trim()},
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AHelperFunction.extractErrorMessage(
                      result,
                      defaultMessage: 'Signup failed. Please try again.',
                    ),
                  ),
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
              SnackBar(
                content: Text('An error occurred. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // Sign in mode - call login API
        setState(() {
          _isLoading = true;
        });

        try {
          // Get identifier based on sign-in method
          String identifier;
          if (_signInMethod == SignInMethod.phone) {
            // For phone, combine country code with phone number
            final countryCode = _signInCountryCode.dialCode ?? '+92';
            identifier = '$countryCode${_signInPhoneController.text.trim()}';
          } else {
            identifier = _signInEmailController.text.trim();
          }

          final result = await _authService.login(
            identifier: identifier,
            password: _signInPasswordController.text,
          );

          setState(() {
            _isLoading = false;
          });

          if (result['success'] == true) {
            // Save token from response
            final responseData = result['data'] as Map<String, dynamic>?;
            debugPrint('📋 Login Response Data: $responseData');
            debugPrint(
              '📋 Login Response Data Keys: ${responseData?.keys.toList()}',
            );

            // Try multiple possible token locations in response
            String? token;

            // Try 1: Direct token in response data
            token = responseData?['token'] as String?;

            // Try 2: Token inside user object
            if ((token == null || token.isEmpty) && responseData != null) {
              final user = responseData['user'] as Map<String, dynamic>?;
              token = user?['token'] as String?;
            }

            // Try 3: Token inside data object (nested)
            if ((token == null || token.isEmpty) && responseData != null) {
              final data = responseData['data'] as Map<String, dynamic>?;
              token = data?['token'] as String?;
            }

            debugPrint(
              '🔑 Extracted Token: ${token != null ? (token.isNotEmpty ? "Token found (length: ${token.length})" : "Token is empty") : "Token is NULL"}',
            );

            if (token != null && token.isNotEmpty) {
              await TokenStorageService.saveToken(token);
              debugPrint('✅ Login token saved to storage successfully');

              // Verify token was saved correctly
              final savedToken = await TokenStorageService.getToken();
              if (savedToken == token) {
                debugPrint(
                  '✅ Token verification: Saved token matches extracted token',
                );
              } else {
                debugPrint(
                  '❌ Token verification failed: Saved token does not match extracted token',
                );
              }
            } else {
              debugPrint('❌ ERROR: No token found in login response!');
              debugPrint('❌ Full response structure: $responseData');
            }

            if (token != null && token.isNotEmpty) {
              final profileResult = await UserService().getUserProfile();
              if (profileResult['success'] == true) {
                final data = profileResult['data'] as Map<String, dynamic>;
                final role = data['role'] as String?;
                if (role != null && role.toLowerCase() != 'driver') {
                  await TokenStorageService.removeToken();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Only driver accounts can login in this app.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
              } else {
                await TokenStorageService.removeToken();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AHelperFunction.extractErrorMessage(
                        profileResult,
                        defaultMessage:
                            'Unable to verify account type. Please try again.',
                      ),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
            }

            if (!mounted) return;
            context.goNamed(ARouter.home);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AHelperFunction.extractErrorMessage(
                      result,
                      defaultMessage: 'Login failed. Please try again.',
                    ),
                  ),
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
  }

  void _switchMode(AuthMode mode) {
    if (_mode != mode) {
      FocusScope.of(context).unfocus();
      setState(() => _mode = mode);
    }
  }

  void _switchSignInMethod(SignInMethod method) {
    if (_signInMethod != method) {
      FocusScope.of(context).unfocus();
      setState(() => _signInMethod = method);
    }
  }

  List<Widget> _buildSignUpFields(BuildContext context) {
    return [
      PrimaryTextFormField(
        controller: _signUpFirstNameController,
        textInputAction: TextInputAction.next,
        hintText: 'First Name',
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter your first name';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      PrimaryTextFormField(
        controller: _signUpLastNameController,
        textInputAction: TextInputAction.next,
        hintText: 'Last Name',
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter your last name';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      PrimaryTextFormField(
        controller: _signUpEmailController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
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
      const SizedBox(height: 16),
      PhoneFormField(
        phoneNumberController: _signUpPhoneController,
        selectedCountryCode: _signUpCountryCode,
        countryFilter: const ['PK', 'AE', 'SA', 'US'],
        onCountryChanged: (code) {
          setState(() => _signUpCountryCode = code);
        },
        phoneNumberValidator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Enter mobile number';
          }
          if (value.trim().length < 7) {
            return 'Enter valid mobile number';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      DropdownFormField(
        hintText: 'Gender',
        value: _selectedGender,
        items: const [
          DropdownMenuItem(value: 'male', child: Text('Male')),
          DropdownMenuItem(value: 'female', child: Text('Female')),
          DropdownMenuItem(value: 'other', child: Text('Other')),
        ],
        onChanged: (value) {
          setState(() {
            _selectedGender = value;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select your gender';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      PasswordFormField(
        controller: _signUpPasswordController,
        textInputAction: TextInputAction.next,
        hintText: 'Password',
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter your password';
          }
          if (value.trim().length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      PasswordFormField(
        controller: _signUpPasswordConfirmationController,
        textInputAction: TextInputAction.done,
        hintText: 'Confirm Password',
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please confirm your password';
          }
          if (value != _signUpPasswordController.text) {
            return 'Passwords do not match';
          }
          return null;
        },
      ),
    ];
  }

  List<Widget> _buildSignInFields(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final onSurface = theme.colorScheme.onSurface;

    return [
      Text(
        _signInMethod == SignInMethod.phone
            ? 'Login with your phone number'
            : 'Login with your email address',
        textAlign: TextAlign.center,
        style: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
      ),
      const SizedBox(height: 20),
      _SignInMethodToggle(
        current: _signInMethod,
        onChanged: _switchSignInMethod,
        highlightColor: _primaryColor,
        textColor: onSurface,
      ),
      const SizedBox(height: 24),
      if (_signInMethod == SignInMethod.phone)
        PhoneFormField(
          phoneNumberController: _signInPhoneController,
          selectedCountryCode: _signInCountryCode,
          countryFilter: const ['PK', 'AE', 'SA', 'US'],
          onCountryChanged: (code) {
            setState(() => _signInCountryCode = code);
          },
          phoneNumberValidator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Enter mobile number';
            }
            if (value.trim().length < 7) {
              return 'Enter valid mobile number';
            }
            return null;
          },
        )
      else
        PrimaryTextFormField(
          controller: _signInEmailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
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
      const SizedBox(height: 16),
      PasswordFormField(
        controller: _signInPasswordController,
        textInputAction: TextInputAction.done,
        hintText: 'Password',
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter your password';
          }
          return null;
        },
      ),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () {
            context.goNamed(ARouter.forgotPassword);
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Forgot Password?',
            style: textTheme.bodyMedium?.copyWith(
              color: _primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildFacebookButton(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.cardColor,
          foregroundColor: onSurface,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _primaryColor, width: 1.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(AImages.facebook, height: 20, width: 20),
            const SizedBox(width: 12),
            Text(
              'Connect with Facebook',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsText(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        text: 'By clicking start, you agree to our ',
        style: theme.textTheme.bodySmall?.copyWith(
          color: onSurface.withValues(alpha: 0.65),
        ),
        children: [
          TextSpan(
            text: 'Terms and Conditions',
            style: TextStyle(fontWeight: FontWeight.w600, color: onSurface),
          ),
        ],
      ),
    );
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
              _SignUpHeader(height: size.height * 0.32),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _AuthTab(
                                label: ATexts.signUp,
                                isSelected: _mode == AuthMode.signUp,
                                color: _primaryColor,
                                onTap: () => _switchMode(AuthMode.signUp),
                                selectedColor: onSurface,
                              ),
                              const SizedBox(width: 32),
                              _AuthTab(
                                label: ATexts.signIn,
                                isSelected: _mode == AuthMode.signIn,
                                color: _primaryColor,
                                onTap: () => _switchMode(AuthMode.signIn),
                                selectedColor: onSurface,
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          ...(_mode == AuthMode.signUp
                              ? _buildSignUpFields(context)
                              : _buildSignInFields(context)),
                          const SizedBox(height: 24),
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
                              text: _mode == AuthMode.signUp
                                  ? ATexts.signUp
                                  : 'Next',
                              onPressed: _isLoading ? () {} : () => _submit(),
                              isLoading: _isLoading,
                            ),
                          ),
                          if (_mode == AuthMode.signUp) ...[
                            const SizedBox(height: 16),
                            _buildFacebookButton(context),
                            const SizedBox(height: 24),
                            _buildTermsText(context),
                          ],
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

class _SignUpHeader extends StatelessWidget {
  const _SignUpHeader({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: _SignUpScreenState._primaryColor,
        ),
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

class _AuthTab extends StatelessWidget {
  const _AuthTab({
    required this.label,
    required this.isSelected,
    required this.color,
    this.onTap,
    required this.selectedColor,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback? onTap;
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final Color unselectedColor = selectedColor.withValues(alpha: 0.45);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isSelected ? selectedColor : unselectedColor,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 4,
            width: isSelected ? 40 : 0,
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignInMethodToggle extends StatelessWidget {
  const _SignInMethodToggle({
    required this.current,
    required this.onChanged,
    required this.highlightColor,
    required this.textColor,
  });

  final SignInMethod current;
  final ValueChanged<SignInMethod> onChanged;
  final Color highlightColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _MethodChip(
          label: 'Phone',
          isSelected: current == SignInMethod.phone,
          onTap: () => onChanged(SignInMethod.phone),
          highlightColor: highlightColor,
          textColor: textColor,
        ),
        const SizedBox(width: 12),
        _MethodChip(
          label: 'Email',
          isSelected: current == SignInMethod.email,
          onTap: () => onChanged(SignInMethod.email),
          highlightColor: highlightColor,
          textColor: textColor,
        ),
      ],
    );
  }
}

class _MethodChip extends StatelessWidget {
  const _MethodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.highlightColor,
    required this.textColor,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color highlightColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? highlightColor.withValues(alpha: 0.18)
              : textColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? highlightColor
                : textColor.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? textColor : textColor.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
