import 'package:draaxi_driver/src/common/utils/image_utils.dart';
// Commented out until logout API is enabled
// import 'package:draaxi_driver/src/features/authentication/service/auth_service.dart';
import 'package:draaxi_driver/src/features/authentication/service/token_storage_service.dart';
import 'package:draaxi_driver/src/features/authentication/service/user_service.dart';
import 'package:draaxi_driver/src/router/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  // Commented out until logout API is enabled
  // final AuthService _authService = AuthService();
  bool _isLoading = true;
  final bool _isLoggingOut = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _userService.getUserProfile();

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      // API returns user data directly, not wrapped in 'user' key
      setState(() {
        _userData = data;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to load profile'),
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadProfile,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with title and search icon
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Profile',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: onSurface,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                // Search functionality
                              },
                              icon: Icon(Icons.search, color: onSurface),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // User profile section - Make clickable
                      InkWell(
                        onTap: () {
                          context.pushNamed(ARouter.editProfile);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              // Profile picture
                              CircleAvatar(
                                radius: 35,
                                backgroundColor: Colors.grey[300],
                                backgroundImage:
                                    _userData?['driver_profile']?['profile_image'] !=
                                        null
                                    ? NetworkImage(
                                        ImageUtils.getImageUrl(
                                          _userData!['driver_profile']['profile_image']
                                              as String?,
                                        ),
                                      )
                                    : null,
                                child:
                                    _userData?['driver_profile']?['profile_image'] ==
                                        null
                                    ? Icon(
                                        Icons.person,
                                        size: 40,
                                        color: Colors.grey[600],
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              // Name and status
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _userData?['name'] as String? ??
                                          'User Name',
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: onSurface,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Trust your feelings, be a good human beings',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: onSurface.withValues(
                                              alpha: 0.6,
                                            ),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Menu items
                      _buildMenuItem(
                        context: context,
                        icon: Icons.person_outline,
                        title: 'Account',
                        onTap: () {
                          context.pushNamed(ARouter.editProfile);
                        },
                        isLoading: false,
                      ),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.location_on_outlined,
                        title: 'Addresses Book',
                        onTap: () {
                          // Navigate to addresses book
                        },
                      ),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.refresh,
                        title: 'Status',
                        onTap: () {
                          // Navigate to status
                        },
                      ),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.notifications_outlined,
                        title: 'Notification',
                        onTap: () {
                          // Navigate to notifications
                        },
                      ),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.chat_bubble_outline,
                        title: 'Chat settings',
                        onTap: () {
                          // Navigate to chat settings
                        },
                      ),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.pie_chart_outline,
                        title: 'Data and storage',
                        onTap: () {
                          // Navigate to data and storage
                        },
                      ),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.lock_outline,
                        title: 'Privacy and security',
                        onTap: () {
                          // Navigate to privacy and security
                        },
                      ),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.info_outline,
                        title: 'About',
                        onTap: () {
                          // Navigate to about
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildMenuItem(
                        context: context,
                        icon: _isLoggingOut ? null : Icons.logout,
                        title: _isLoggingOut ? 'Logging out...' : 'Logout',
                        onTap: _isLoggingOut ? () {} : _handleLogout,
                        isLoading: _isLoggingOut,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData? icon,
    required String title,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    final theme = Theme.of(context);
    final primaryColor = const Color(0xFFFEC400);
    final onSurface = theme.colorScheme.onSurface;

    return InkWell(
      onTap: isLoading ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    )
                  : icon != null
                  ? Icon(icon, color: primaryColor, size: 24)
                  : const SizedBox(width: 24, height: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (!isLoading)
              Icon(
                Icons.chevron_right,
                color: onSurface.withValues(alpha: 0.4),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    // Remove all authentication data from local storage
    await TokenStorageService.removeToken();
    await TokenStorageService.removeResetToken();

    if (mounted) {
      context.goNamed(ARouter.signIn);
    }

    // Commented out logout API feature - will be enabled later
    /*
    setState(() {
      _isLoggingOut = true;
    });

    try {
      final result = await _authService.logout();

      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });

        if (result['success'] == true) {
          // Token is already removed in AuthService.logout() on success
          // But ensure it's removed here as well for safety
          await TokenStorageService.removeToken();
          
          // Note: Providers will be reset when app restarts
          // Since we're removing the token and navigating to onboarding,
          // the redirect logic will handle proper state management
          
          // Navigate to onboarding screen only on successful logout
          if (mounted) {
            context.goNamed(ARouter.onboarding);
          }
        } else {
          // Show error snackbar if logout API fails
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Logout failed. Please try again.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          // Don't navigate or remove token if API fails
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        // Don't navigate or remove token if there's an error
      }
    }
    */
  }
}
