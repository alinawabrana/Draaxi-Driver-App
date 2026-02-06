import 'package:draaxi_driver/onboarding_screen.dart';
import 'package:draaxi_driver/src/features/authentication/screens/forgot_password_screen.dart';
import 'package:draaxi_driver/src/features/authentication/screens/otp_verification_screen.dart';
import 'package:draaxi_driver/src/features/authentication/screens/reset_password_screen.dart';
import 'package:draaxi_driver/src/features/authentication/screens/sign_in_screen.dart';
import 'package:draaxi_driver/src/features/authentication/screens/sign_up_screen.dart';
import 'package:draaxi_driver/src/features/authentication/service/token_storage_service.dart';
import 'package:draaxi_driver/src/features/authentication/service/user_service.dart';
import 'package:draaxi_driver/src/features/chat/screens/chat_screen.dart';
import 'package:draaxi_driver/src/features/home/screens/home_screen.dart';
import 'package:draaxi_driver/src/features/profile/screens/edit_profile_screen.dart';
import 'package:draaxi_driver/src/features/profile/screens/document_upload_screen.dart';
import 'package:draaxi_driver/src/features/profile/screens/profile_screen.dart';
import 'package:draaxi_driver/src/features/wallet/screens/wallet_screen.dart';
import 'package:draaxi_driver/src/router/main_shell.dart';
import 'package:draaxi_driver/src/router/router.dart';
import 'package:go_router/go_router.dart';

class AppRoutes {
  static GoRouter routes = GoRouter(
    initialLocation: '/onBoarding',
    redirect: (context, state) async {
      // Check if user has auth token
      final hasToken = await TokenStorageService.hasToken();
      final token = await TokenStorageService.getToken();
      final isAuthenticated = hasToken && token != null && token.isNotEmpty;

      final isOnBoarding = state.matchedLocation == '/onBoarding';
      final isDocumentUpload = state.matchedLocation.startsWith(
        '/documentUpload',
      );

      // Check if user is trying to access OTP verification routes (these should be accessible even with token)
      // These routes can be nested (e.g., /signUp/signupOtpVerification) or direct
      final isOtpRoute =
          state.matchedLocation.contains('/signinOtpVerification') ||
          state.matchedLocation.contains('/signupOtpVerification') ||
          state.matchedLocation.contains('/forgotPasswordOtpVerification') ||
          state.matchedLocation.contains('/setNewPassword');

      final isAuthRoute =
          state.matchedLocation.startsWith('/signIn') ||
          state.matchedLocation.startsWith('/signUp') ||
          state.matchedLocation.startsWith('/forgotPassword');

      bool? documentsUploaded;
      if (isAuthenticated) {
        documentsUploaded = await TokenStorageService.getDocumentsUploaded();
        if (documentsUploaded == null) {
          final result = await UserService().getUserProfile();
          if (result['success'] == true) {
            final data = result['data'] as Map<String, dynamic>;
            final role = data['role'] as String?;
            if (role != null && role.toLowerCase() != 'driver') {
              await TokenStorageService.removeToken();
              return '/signIn?error=driver_only';
            }
            final driverProfile =
                data['driver_profile'] as Map<String, dynamic>?;
            final vehicleDoc = driverProfile?['vehicle_doc'] as String?;
            final licenseDoc = driverProfile?['license_doc'] as String?;
            final vehicleType = driverProfile?['vehicle_type'] as String?;
            final vehicleNo = driverProfile?['vehicle_no'] as String?;
            final licenseNo = driverProfile?['license_no'] as String?;
            final computedUploaded =
                (vehicleDoc != null && vehicleDoc.isNotEmpty) &&
                (licenseDoc != null && licenseDoc.isNotEmpty) &&
                (vehicleType != null && vehicleType.isNotEmpty) &&
                (vehicleNo != null && vehicleNo.isNotEmpty) &&
                (licenseNo != null && licenseNo.isNotEmpty);
            documentsUploaded = computedUploaded;
            await TokenStorageService.saveDocumentsUploaded(computedUploaded);
          } else {
            documentsUploaded = false;
            await TokenStorageService.saveDocumentsUploaded(false);
          }
        }
      }

      if (isAuthenticated &&
          documentsUploaded == false &&
          !isDocumentUpload &&
          !isOtpRoute) {
        final result = await UserService().getUserProfile();
        if (result['success'] == true) {
          final data = result['data'] as Map<String, dynamic>;
          final role = data['role'] as String?;
          if (role != null && role.toLowerCase() != 'driver') {
            await TokenStorageService.removeToken();
            return '/signIn?error=driver_only';
          }
        }
        final returnTo = Uri.encodeComponent(state.uri.toString());
        return '/documentUpload?returnTo=$returnTo';
      }

      // If user is authenticated and trying to access auth/onboarding pages, redirect to home
      // BUT allow OTP verification routes even if authenticated (token from signup needs OTP verification)
      // Also, don't redirect if already on an OTP route
      if (isAuthenticated && (isOnBoarding || isAuthRoute) && !isOtpRoute) {
        if (documentsUploaded == false) {
          return '/documentUpload?returnTo=%2Fhome';
        }
        return '/home';
      }

      // If user is not authenticated and trying to access protected routes, redirect to onboarding
      // Allow OTP routes and auth routes for unauthenticated users
      if (!isAuthenticated && !isOnBoarding && !isAuthRoute && !isOtpRoute) {
        return '/onBoarding';
      }

      if (isAuthenticated && documentsUploaded == true && isDocumentUpload) {
        final rawReturnTo = state.uri.queryParameters['returnTo'];
        final target = (rawReturnTo != null && rawReturnTo.isNotEmpty)
            ? Uri.decodeComponent(rawReturnTo)
            : '/home';
        return target;
      }

      // No redirect needed
      return null;
    },
    routes: [
      GoRoute(
        path: '/onBoarding',
        name: ARouter.onboarding,
        builder: (context, state) => const OnBoardingScreen(),
      ),
      // GoRoute(
      //   path: '/welcome',
      //   name: ARouter.welcome,
      //   builder: (context, state) => const WelcomeScreen(),
      //   routes: [
      GoRoute(
        path: '/signUp',
        name: ARouter.signUp,
        builder: (context, state) => const SignUpScreen(),
        routes: [
          GoRoute(
            path: 'signupOtpVerification',
            name: ARouter.signupOtpVerification,
            builder: (context, state) {
              // Email is passed via query parameters from sign up screen
              // Accessible via state.uri.queryParameters['email']
              return OtpVerificationScreen(
                email: state.uri.queryParameters['email'] ?? '',
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/signIn',
        name: ARouter.signIn,
        builder: (context, state) =>
            SignInScreen(error: state.uri.queryParameters['error']),
        routes: [
          GoRoute(
            path: 'signinOtpVerification',
            name: ARouter.signinOtpVerification,
            builder: (context, state) {
              // Email is passed via query parameters from sign in screen
              return OtpVerificationScreen(
                email: state.uri.queryParameters['email'] ?? '',
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/forgotPassword',
        name: ARouter.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
        routes: [
          GoRoute(
            path: 'forgotPasswordOtpVerification',
            name: ARouter.forgotPasswordOtpVerification,
            builder: (context, state) {
              // Email is passed via query parameters from forgot password screen
              return OtpVerificationScreen(
                email: state.uri.queryParameters['email'] ?? '',
                otpType: OtpType.forgotPassword,
              );
            },
            routes: [
              GoRoute(
                path: 'setNewPassword',
                name: ARouter.setNewPassword,
                builder: (context, state) {
                  // Email is passed via query parameters from OTP verification screen
                  return ResetPasswordScreen(
                    email: state.uri.queryParameters['email'] ?? '',
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/documentUpload',
        name: ARouter.documentUpload,
        builder: (context, state) {
          final rawReturnTo = state.uri.queryParameters['returnTo'];
          final decoded = (rawReturnTo != null && rawReturnTo.isNotEmpty)
              ? Uri.decodeComponent(rawReturnTo)
              : null;
          return DocumentUploadScreen(returnTo: decoded);
        },
      ),
      ShellRoute(
        navigatorKey: ARouter.shellKey,
        builder: (context, state, child) {
          return MainShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            name: ARouter.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/wallet',
            name: ARouter.wallet,
            builder: (context, state) => const WalletScreen(),
          ),
          GoRoute(
            path: '/chat',
            name: ARouter.chat,
            builder: (context, state) => const ChatScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: ARouter.profile,
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: '/edit',
                name: ARouter.editProfile,
                builder: (context, state) => const EditProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
