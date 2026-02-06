import 'dart:io';
import 'package:draaxi_driver/src/common/widgets/primary_button.dart';
import 'package:draaxi_driver/src/common/widgets/primary_text_form_field.dart';
import 'package:draaxi_driver/src/features/authentication/service/token_storage_service.dart';
import 'package:draaxi_driver/src/features/authentication/service/user_service.dart';
import 'package:draaxi_driver/utils/helpers/helper_function.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key, this.returnTo});

  final String? returnTo;

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final UserService _userService = UserService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _loadingProfile = true;
  bool _submitting = false;
  Map<String, dynamic>? _userData;
  int _stepIndex = 0;

  File? _vehicleDoc;
  File? _licenseDoc;

  String? _existingVehicleDocUrl;
  String? _existingLicenseDocUrl;
  final TextEditingController _vehicleTypeController = TextEditingController();
  final TextEditingController _vehicleNoController = TextEditingController();
  final TextEditingController _vehicleDescriptionController =
      TextEditingController();
  final TextEditingController _licenseNoController = TextEditingController();

  @override
  void dispose() {
    _vehicleTypeController.dispose();
    _vehicleNoController.dispose();
    _vehicleDescriptionController.dispose();
    _licenseNoController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loadingProfile = true;
    });

    final result = await _userService.getUserProfile();

    setState(() {
      _loadingProfile = false;
    });

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      final role = data['role'] as String?;
      if (role != null && role.toLowerCase() != 'driver') {
        await TokenStorageService.removeToken();
        if (!mounted) return;
        context.go('/signIn?error=driver_only');
        return;
      }
      final driverProfile = data['driver_profile'] as Map<String, dynamic>?;

      setState(() {
        _userData = data;
        _existingVehicleDocUrl = driverProfile?['vehicle_doc'] as String?;
        _existingLicenseDocUrl = driverProfile?['license_doc'] as String?;
        _vehicleTypeController.text =
            driverProfile?['vehicle_type'] as String? ?? '';
        _vehicleNoController.text =
            driverProfile?['vehicle_no'] as String? ?? '';
        _vehicleDescriptionController.text =
            driverProfile?['vehicle_description'] as String? ?? '';
        _licenseNoController.text =
            driverProfile?['license_no'] as String? ?? '';
      });

      final uploaded = _hasAllRequiredUploads();
      await TokenStorageService.saveDocumentsUploaded(uploaded);
      if (!mounted) return;
      if (uploaded) {
        final target = (widget.returnTo?.isNotEmpty ?? false)
            ? widget.returnTo!
            : '/home';
        context.go(target);
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

  bool _isUploaded(String? existingUrl, File? pickedFile) {
    if (pickedFile != null) return true;
    return existingUrl != null && existingUrl.isNotEmpty;
  }

  bool _isFilled(String value) => value.trim().isNotEmpty;

  bool _hasVehicleDetails() {
    return _isFilled(_vehicleTypeController.text) &&
        _isFilled(_vehicleNoController.text);
  }

  bool _hasLicenseDetails() {
    return _isFilled(_licenseNoController.text);
  }

  bool _hasAllRequiredUploads() {
    return _isUploaded(_existingVehicleDocUrl, _vehicleDoc) &&
        _isUploaded(_existingLicenseDocUrl, _licenseDoc) &&
        _hasVehicleDetails() &&
        _hasLicenseDetails();
  }

  Future<void> _pickDocument(String type) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final pickedFile = result.files.first;
      if (pickedFile.path == null || pickedFile.path!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Unable to access selected file. Please try again.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final extension = pickedFile.extension?.toLowerCase() ?? '';
      final allowedExtensions = ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'];
      if (!allowedExtensions.contains(extension)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please select a valid file format (PDF, DOC, DOCX, JPG, JPEG, PNG)',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final file = File(pickedFile.path!);
      setState(() {
        if (type == 'vehicle') {
          _vehicleDoc = file;
        } else if (type == 'license') {
          _licenseDoc = file;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick document: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_userData == null) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (!_hasAllRequiredUploads()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill required details and upload both documents to continue.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    final name = _userData?['name'] as String? ?? '';
    final email = _userData?['email'] as String? ?? '';
    final phone = _userData?['phone'] as String? ?? '';

    try {
      final result = await _userService.updateDriverProfile(
        name: name,
        email: email,
        phone: phone,
        vehicleType: _vehicleTypeController.text.trim(),
        vehicleNo: _vehicleNoController.text.trim(),
        vehicleDescription: _vehicleDescriptionController.text.trim().isEmpty
            ? null
            : _vehicleDescriptionController.text.trim(),
        licenseNo: _licenseNoController.text.trim(),
        vehicleDoc: _vehicleDoc,
        licenseDoc: _licenseDoc,
      );

      setState(() {
        _submitting = false;
      });

      if (result['success'] == true) {
        await TokenStorageService.saveDocumentsUploaded(true);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Documents uploaded successfully. Please wait for admin approval to move forward with driving.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 800));

        if (!mounted) return;
        final target = (widget.returnTo?.isNotEmpty ?? false)
            ? widget.returnTo!
            : '/home';
        context.go(target);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AHelperFunction.extractErrorMessage(
                result,
                defaultMessage: 'Failed to upload documents. Please try again.',
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _submitting = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildUploadTile({
    required String title,
    required String subtitle,
    required bool uploaded,
    required VoidCallback onTap,
    Widget? preview,
  }) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          color: uploaded ? Colors.green.withValues(alpha: 0.06) : null,
        ),
        child: Row(
          children: [
            if (preview != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(width: 56, height: 56, child: preview),
              ),
              const SizedBox(width: 12),
            ] else ...[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey.shade100,
                ),
                child: Icon(
                  uploaded ? Icons.check_circle : Icons.upload_file,
                  color: uploaded ? Colors.green : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.chevron_right, color: onSurface.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Upload Documents'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadProfile,
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Complete your vehicle and license details to continue.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'After uploading, your documents will be reviewed by the admin team.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: _stepIndex >= 0
                                    ? theme.colorScheme.primary
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: _stepIndex >= 1
                                    ? theme.colorScheme.primary
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _stepIndex == 0
                            ? Column(
                                key: const ValueKey('vehicleStep'),
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Vehicle',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: onSurface,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  PrimaryTextFormField(
                                    controller: _vehicleTypeController,
                                    hintText: 'Vehicle Type',
                                    textInputAction: TextInputAction.next,
                                    onChanged: (_) => setState(() {}),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Please enter vehicle type';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  PrimaryTextFormField(
                                    controller: _vehicleNoController,
                                    hintText: 'Vehicle Number',
                                    textInputAction: TextInputAction.next,
                                    onChanged: (_) => setState(() {}),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Please enter vehicle number';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  PrimaryTextFormField(
                                    controller: _vehicleDescriptionController,
                                    hintText: 'Vehicle Description (optional)',
                                    textInputAction: TextInputAction.done,
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildUploadTile(
                                    title: 'Vehicle Document',
                                    subtitle:
                                        _isUploaded(
                                          _existingVehicleDocUrl,
                                          _vehicleDoc,
                                        )
                                        ? (_vehicleDoc != null
                                              ? _vehicleDoc!.path
                                                    .split('/')
                                                    .last
                                              : 'Uploaded')
                                        : 'Tap to upload',
                                    uploaded: _isUploaded(
                                      _existingVehicleDocUrl,
                                      _vehicleDoc,
                                    ),
                                    onTap: () => _pickDocument('vehicle'),
                                  ),
                                  const SizedBox(height: 24),
                                  PrimaryButton(
                                    text: 'Next',
                                    onPressed: () {
                                      final ok =
                                          _formKey.currentState?.validate() ??
                                          false;
                                      if (!ok) return;
                                      setState(() {
                                        _stepIndex = 1;
                                      });
                                    },
                                    enabled:
                                        !_submitting &&
                                        _hasVehicleDetails() &&
                                        _isUploaded(
                                          _existingVehicleDocUrl,
                                          _vehicleDoc,
                                        ),
                                  ),
                                ],
                              )
                            : Column(
                                key: const ValueKey('licenseStep'),
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'License',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: onSurface,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  PrimaryTextFormField(
                                    controller: _licenseNoController,
                                    hintText: 'License Number',
                                    textInputAction: TextInputAction.done,
                                    onChanged: (_) => setState(() {}),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Please enter license number';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _buildUploadTile(
                                    title: 'Driving License Document',
                                    subtitle:
                                        _isUploaded(
                                          _existingLicenseDocUrl,
                                          _licenseDoc,
                                        )
                                        ? (_licenseDoc != null
                                              ? _licenseDoc!.path
                                                    .split('/')
                                                    .last
                                              : 'Uploaded')
                                        : 'Tap to upload',
                                    uploaded: _isUploaded(
                                      _existingLicenseDocUrl,
                                      _licenseDoc,
                                    ),
                                    onTap: () => _pickDocument('license'),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: _submitting
                                              ? null
                                              : () {
                                                  setState(() {
                                                    _stepIndex = 0;
                                                  });
                                                },
                                          child: const Text('Back'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: PrimaryButton(
                                          text: 'Submit',
                                          onPressed: _submit,
                                          isLoading: _submitting,
                                          enabled:
                                              _hasAllRequiredUploads() &&
                                              !_submitting,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
