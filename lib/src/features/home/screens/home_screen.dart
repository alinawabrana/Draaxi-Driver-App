import 'package:draaxi_driver/src/features/authentication/service/user_service.dart';
import 'package:draaxi_driver/src/router/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserService _userService = UserService();
  bool _hasCheckedProfile = false;

  bool _requiresProfileCompletion(Map<String, dynamic>? driverProfile) {
    if (driverProfile == null || driverProfile.isEmpty) {
      return true;
    }

    final vehicleDoc = driverProfile['vehicle_doc'] as String?;
    final licenseDoc = driverProfile['license_doc'] as String?;
    final vehicleType = driverProfile['vehicle_type'] as String?;
    final vehicleNo = driverProfile['vehicle_no'] as String?;
    final licenseNo = driverProfile['license_no'] as String?;

    return (vehicleDoc == null || vehicleDoc.isEmpty) ||
        (licenseDoc == null || licenseDoc.isEmpty) ||
        (vehicleType == null || vehicleType.isEmpty) ||
        (vehicleNo == null || vehicleNo.isEmpty) ||
        (licenseNo == null || licenseNo.isEmpty);
  }

  Future<void> _showProfileCompletionDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          title: const Text('Profile Verification Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Please verify your documents before proceeding.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              Text(
                '• Visit the nearest branch to verify your documents immediately.',
              ),
              SizedBox(height: 8),
              Text('• Or upload the required documents through the app.'),
              SizedBox(height: 12),
              Text(
                'Note: Documents uploaded through the app may take some time to be approved by the admin team.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (mounted) {
                  context.goNamed(ARouter.documentUpload);
                }
              },
              child: const Text('Upload Documents'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDriverProfile();
    });
  }

  Future<void> _checkDriverProfile() async {
    if (_hasCheckedProfile) return;

    setState(() {
      _hasCheckedProfile = true;
    });

    final result = await _userService.getUserProfile();

    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      // API returns user data directly, not wrapped in 'user' key
      final driverProfile = data['driver_profile'] as Map<String, dynamic>?;

      // Check if driver profile exists
      if (_requiresProfileCompletion(driverProfile)) {
        Future.microtask(() async {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please upload the required documents to continue.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          await _showProfileCompletionDialog();
        });
      }
    } else {
      // Handle errors
      final error = result['error'] as String?;
      if (error?.toLowerCase().contains('unauthenticated') == true ||
          error?.toLowerCase().contains('401') == true) {
        // Token missing or invalid - redirect to login
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please login again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              context.goNamed(ARouter.signIn);
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Center(
        child: Text(
          'Coming Soon',
          style: theme.textTheme.headlineMedium?.copyWith(color: onSurface),
        ),
      ),
    );
  }
}
