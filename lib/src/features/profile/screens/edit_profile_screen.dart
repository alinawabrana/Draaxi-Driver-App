import 'dart:io';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:draaxi_driver/src/common/utils/image_utils.dart';
import 'package:draaxi_driver/src/common/widgets/phone_form_field.dart';
import 'package:draaxi_driver/src/common/widgets/primary_button.dart';
import 'package:draaxi_driver/src/common/widgets/primary_text_form_field.dart';
import 'package:draaxi_driver/src/features/authentication/service/user_service.dart';
import 'package:draaxi_driver/utils/helpers/helper_function.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _vehicleTypeController = TextEditingController();
  final TextEditingController _vehicleNoController = TextEditingController();
  final TextEditingController _vehicleDescriptionController =
      TextEditingController();
  final TextEditingController _licenseNoController = TextEditingController();

  CountryCode _countryCode = CountryCode.fromDialCode('+92');
  bool _isLoading = false;
  bool _isLoadingProfile = true;
  final UserService _userService = UserService();
  static const Color _primaryColor = Color(0xFFFEC400);
  final ImagePicker _imagePicker = ImagePicker();

  File? _profileImage;
  File? _vehicleDoc;
  File? _licenseDoc;
  String? _existingProfileImageUrl;
  String? _existingVehicleDocUrl;
  String? _existingLicenseDocUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _vehicleTypeController.dispose();
    _vehicleNoController.dispose();
    _vehicleDescriptionController.dispose();
    _licenseNoController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoadingProfile = true;
    });

    final result = await _userService.getUserProfile();

    setState(() {
      _isLoadingProfile = false;
    });

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      // API returns user data directly
      final user = data;
      final driverProfile = data['driver_profile'] as Map<String, dynamic>?;

      // API returns user data directly
      _nameController.text = user['name'] as String? ?? '';
      _emailController.text = user['email'] as String? ?? '';

      final phone = user['phone'] as String? ?? '';
      if (phone.isNotEmpty) {
        if (phone.startsWith('+')) {
          final parts = phone.split(' ');
          if (parts.length > 1) {
            _countryCode = CountryCode.fromDialCode(parts[0]);
            _phoneController.text = parts.sublist(1).join(' ');
          } else {
            for (final code in ['+92', '+1', '+971', '+966']) {
              if (phone.startsWith(code)) {
                _countryCode = CountryCode.fromDialCode(code);
                _phoneController.text = phone.substring(code.length);
                break;
              }
            }
          }
        } else {
          _phoneController.text = phone;
        }
      }

      if (driverProfile != null) {
        _cityController.text = driverProfile['city'] as String? ?? '';
        _districtController.text = driverProfile['district'] as String? ?? '';
        _vehicleTypeController.text =
            driverProfile['vehicle_type'] as String? ?? '';
        _vehicleNoController.text =
            driverProfile['vehicle_no'] as String? ?? '';
        _vehicleDescriptionController.text =
            driverProfile['vehicle_description'] as String? ?? '';
        _licenseNoController.text =
            driverProfile['license_no'] as String? ?? '';
        _existingProfileImageUrl = driverProfile['profile_image'] as String?;
        _existingVehicleDocUrl = driverProfile['vehicle_doc'] as String?;
        _existingLicenseDocUrl = driverProfile['license_doc'] as String?;
      }
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickDocument(String type) async {
    try {
      // Use FileType.any for better mobile compatibility
      // On mobile, FileType.custom with extensions may not work properly
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;

        // Check if file path exists (for mobile platforms)
        if (pickedFile.path != null && pickedFile.path!.isNotEmpty) {
          final file = File(pickedFile.path!);

          // Validate file extension
          final extension = pickedFile.extension?.toLowerCase() ?? '';
          final allowedExtensions = [
            'pdf',
            'doc',
            'docx',
            'jpg',
            'jpeg',
            'png',
          ];

          if (allowedExtensions.contains(extension)) {
            setState(() {
              if (type == 'vehicle') {
                _vehicleDoc = file;
              } else if (type == 'license') {
                _licenseDoc = file;
              }
            });
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Please select a valid file format (PDF, DOC, DOCX, JPG, JPEG, PNG)',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        } else if (pickedFile.bytes != null) {
          // Handle web platform where path might be null but bytes are available
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'File picking from web is not supported. Please use mobile app.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick document: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('File picker error: $e');
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      setState(() {
        _isLoading = true;
      });

      try {
        final countryCode = _countryCode.dialCode ?? '+92';
        final fullPhone = '$countryCode${_phoneController.text.trim()}';

        final result = await _userService.updateDriverProfile(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: fullPhone,
          city: _cityController.text.trim().isEmpty
              ? null
              : _cityController.text.trim(),
          district: _districtController.text.trim().isEmpty
              ? null
              : _districtController.text.trim(),
          vehicleType: _vehicleTypeController.text.trim().isEmpty
              ? null
              : _vehicleTypeController.text.trim(),
          vehicleNo: _vehicleNoController.text.trim().isEmpty
              ? null
              : _vehicleNoController.text.trim(),
          vehicleDescription: _vehicleDescriptionController.text.trim().isEmpty
              ? null
              : _vehicleDescriptionController.text.trim(),
          licenseNo: _licenseNoController.text.trim().isEmpty
              ? null
              : _licenseNoController.text.trim(),
          profileImage: _profileImage,
          vehicleDoc: _vehicleDoc,
          licenseDoc: _licenseDoc,
        );

        setState(() {
          _isLoading = false;
        });

        if (result['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            context.pop();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AHelperFunction.extractErrorMessage(
                    result,
                    defaultMessage:
                        'Failed to update profile. Please try again.',
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
              content: Text('An error occurred: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildImagePicker({
    required String label,
    required File? file,
    required String? existingUrl,
    required VoidCallback onTap,
  }) {
    // Check if this is the profile image - make it circular
    final isProfileImage = label.toLowerCase().contains('profile');
    final size = isProfileImage ? 120.0 : 100.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Center(
            child: isProfileImage
                ? // Circular profile image
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                      color: Colors.grey.shade200,
                    ),
                    child: file != null
                        ? ClipOval(
                            child: Image.file(
                              file,
                              fit: BoxFit.cover,
                              width: size,
                              height: size,
                            ),
                          )
                        : existingUrl != null && existingUrl.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              ImageUtils.getImageUrl(existingUrl),
                              fit: BoxFit.cover,
                              width: size,
                              height: size,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.add_photo_alternate,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                  )
                : // Regular rounded rectangle for other images
                  Container(
                    height: size,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: file != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.file(file, fit: BoxFit.cover),
                          )
                        : existingUrl != null && existingUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              ImageUtils.getImageUrl(existingUrl),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.image,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Tap to add image',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentPicker({
    required String label,
    required File? file,
    required String? existingUrl,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            // If document exists, show dialog with view/upload options
            if (file == null && existingUrl != null && existingUrl.isNotEmpty) {
              _showDocumentOptionsDialog(label, existingUrl, onTap);
            } else {
              // If no document, directly pick new one
              onTap();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.insert_drive_file, color: _primaryColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file != null
                            ? file.path.split('/').last
                            : existingUrl != null && existingUrl.isNotEmpty
                            ? 'Document uploaded'
                            : 'Tap to select document',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (file == null &&
                          existingUrl != null &&
                          existingUrl.isNotEmpty)
                        Text(
                          'Tap to view or change',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showDocumentOptionsDialog(
    String label,
    String documentUrl,
    VoidCallback onUploadNew,
  ) async {
    final documentFullUrl = ImageUtils.getImageUrl(documentUrl);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility, color: Colors.blue),
              title: const Text('View Document'),
              onTap: () async {
                Navigator.of(context).pop();
                await _viewDocument(documentFullUrl);
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file, color: Colors.orange),
              title: const Text('Upload New Document'),
              onTap: () {
                Navigator.of(context).pop();
                onUploadNew();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _viewDocument(String url) async {
    try {
      debugPrint('📄 Attempting to open document: $url');

      // Try custom platform channel first (will work after rebuild)
      try {
        const platform = MethodChannel('com.example.draaxi_driver/open_url');
        final result = await platform.invokeMethod('openUrl', url);
        debugPrint('✅ Document opened successfully in Chrome: $result');
        return;
      } on MissingPluginException {
        debugPrint(
          '⚠️ Platform channel not registered yet - showing dialog instead',
        );
        // Native code not registered - show dialog with copy option
      } on PlatformException catch (e) {
        debugPrint('❌ Platform channel failed: ${e.message}');
        // Show dialog with copy option
      } catch (e) {
        debugPrint('❌ Failed to open document: $e');
        // Show dialog with copy option
      }

      // Show dialog with URL and copy option
      if (mounted) {
        _showDocumentUrlDialog(url);
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
      if (mounted) {
        _showDocumentUrlDialog(url);
      }
    }
  }

  Future<void> _showDocumentUrlDialog(String url) async {
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Open Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unable to open document automatically. Tap the link below to open it in your browser.',
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final navigator = Navigator.of(dialogContext);
                final messenger = ScaffoldMessenger.of(context);
                navigator.pop(); // Close dialog first

                // Try multiple methods to open URL
                bool opened = false;

                // Method 1: Try custom platform channel
                try {
                  const platform = MethodChannel(
                    'com.example.draaxi_driver/open_url',
                  );
                  await platform.invokeMethod('openUrl', url);
                  opened = true;
                  debugPrint('✅ Opened using custom platform channel');
                } catch (e) {
                  debugPrint('⚠️ Custom platform channel failed: $e');
                }

                // Method 2: Try url_launcher if custom channel failed
                if (!opened) {
                  try {
                    final uri = Uri.parse(url);
                    // Try without canLaunchUrl check first (to avoid channel errors)
                    opened = await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                    if (opened) {
                      debugPrint('✅ Opened using url_launcher');
                    }
                  } catch (e) {
                    debugPrint('⚠️ url_launcher failed: $e');
                    // Try with canLaunchUrl as fallback
                    try {
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        opened = await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                        if (opened) {
                          debugPrint(
                            '✅ Opened using url_launcher (with check)',
                          );
                        }
                      }
                    } catch (e2) {
                      debugPrint('⚠️ url_launcher with check also failed: $e2');
                    }
                  }
                }

                // Method 3: Try platformDefault mode
                if (!opened) {
                  try {
                    final uri = Uri.parse(url);
                    opened = await launchUrl(
                      uri,
                      mode: LaunchMode.platformDefault,
                    );
                    if (opened) {
                      debugPrint(
                        '✅ Opened using url_launcher (platformDefault)',
                      );
                    }
                  } catch (e) {
                    debugPrint('⚠️ platformDefault mode also failed: $e');
                  }
                }

                // Final fallback: Copy to clipboard
                if (!opened) {
                  await Clipboard.setData(ClipboardData(text: url));
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Could not open link automatically. Link copied to clipboard. Please paste it in your browser.',
                      ),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        url,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.blue,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the link above or copy it using the button below',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(ClipboardData(text: url));
              if (!mounted) return;
              navigator.pop();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Document link copied to clipboard'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Copy Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        // Profile Image
                        _buildImagePicker(
                          label: 'Profile Image',
                          file: _profileImage,
                          existingUrl: _existingProfileImageUrl,
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) => SafeArea(
                                child: Wrap(
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.camera_alt),
                                      title: const Text('Camera'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _pickImage(ImageSource.camera);
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.photo_library),
                                      title: const Text('Gallery'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _pickImage(ImageSource.gallery);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        PrimaryTextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          hintText: 'Name',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        PrimaryTextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          hintText: 'Email',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email';
                            }
                            final emailRegex = RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            );
                            if (!emailRegex.hasMatch(value.trim())) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        PhoneFormField(
                          phoneNumberController: _phoneController,
                          selectedCountryCode: _countryCode,
                          countryFilter: const ['PK', 'AE', 'SA', 'US'],
                          onCountryChanged: (code) {
                            setState(() {
                              _countryCode = code;
                            });
                          },
                          phoneNumberValidator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your phone number';
                            }
                            if (value.trim().length < 7) {
                              return 'Please enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        PrimaryTextFormField(
                          controller: _cityController,
                          textInputAction: TextInputAction.next,
                          hintText: 'City',
                        ),
                        const SizedBox(height: 16),
                        PrimaryTextFormField(
                          controller: _districtController,
                          textInputAction: TextInputAction.next,
                          hintText: 'District',
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Vehicle Information',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        PrimaryTextFormField(
                          controller: _vehicleTypeController,
                          textInputAction: TextInputAction.next,
                          hintText: 'Vehicle Type',
                        ),
                        const SizedBox(height: 16),
                        PrimaryTextFormField(
                          controller: _vehicleNoController,
                          textInputAction: TextInputAction.next,
                          hintText: 'Vehicle Number',
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _vehicleDescriptionController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            hintText: 'Vehicle Description',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: _primaryColor,
                              ),
                            ),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        _buildDocumentPicker(
                          label: 'Vehicle Document',
                          file: _vehicleDoc,
                          existingUrl: _existingVehicleDocUrl,
                          onTap: () => _pickDocument('vehicle'),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'License Information',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        PrimaryTextFormField(
                          controller: _licenseNoController,
                          textInputAction: TextInputAction.next,
                          hintText: 'License Number',
                        ),
                        const SizedBox(height: 16),
                        _buildDocumentPicker(
                          label: 'License Document',
                          file: _licenseDoc,
                          existingUrl: _existingLicenseDocUrl,
                          onTap: () => _pickDocument('license'),
                        ),
                        const SizedBox(height: 32),
                        PrimaryButton(
                          text: 'Save Changes',
                          onPressed: _isLoading ? () {} : () => _submit(),
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
