import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_role.dart';
import '../../../providers/farmora_state.dart';
import '../../home/presentation/home_screen.dart';
import 'login_screen.dart';
import 'phone_otp_dialog.dart';
import 'role_selection_screen.dart';

/// Clean, modern, and accessible registration form screen for Farmora.
///
/// Features role context banner, optional profile photo upload,
/// large input fields for Name, Phone, Password, Confirm Password, District/Location,
/// and a prominent primary "Create Account" button.
class RegisterScreen extends StatefulWidget {
  final Role selectedRole;
  final VoidCallback? onRegistered;

  const RegisterScreen({
    super.key,
    this.selectedRole = Role.farmer,
    this.onRegistered,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedDistrict;
  bool _hasPhoto = false;
  Uint8List? _photoBytes;
  String? _photoFileName;
  String? _photoContentType;
  bool _isLoading = false;

  static const List<String> _districts = [
    'Nuwara Eliya',
    'Kandy',
    'Colombo',
    'Kurunegala',
    'Anuradhapura',
    'Matale',
    'Badulla',
    'Gampaha',
    'Hambantota',
    'Jaffna',
    'Galle',
    'Ratnapura',
    'Monaragala',
    'Polonnaruwa',
    'Puttalam',
    'Kalutara',
    'Kegalle',
    'Matara',
    'Batticaloa',
    'Ampara',
    'Trincomalee',
    'Vavuniya',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleOtpRegister() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty || _selectedDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your name, phone number, and district.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    final state = context.read<FarmoraState>();
    final sent = await state.sendPhoneOtp(phone);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (!sent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.authError ?? 'Could not send OTP.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final verified = await showPhoneOtpDialog(
      context: context,
      phone: phone,
      verify: (code) => state.verifyPhoneOtpRegistration(
        code: code,
        name: name,
        phone: phone,
        role: widget.selectedRole,
        district: _selectedDistrict,
      ),
      resend: () => state.sendPhoneOtp(phone),
      error: () => state.authError,
    );
    if (!mounted || !verified) return;
    if (_photoBytes != null && _photoFileName != null) {
      await state.uploadProfilePhoto(
        bytes: _photoBytes!,
        fileName: _photoFileName!,
        contentType: _photoContentType ?? 'image/jpeg',
      );
    }
    if (!mounted) return;
    widget.onRegistered?.call();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Phone verified and account created.'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _handleGoogleRegister() async {
    final phone = _phoneController.text.trim();
    if (!RegExp(r'^\+?[0-9 ]{9,18}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Enter a valid mobile number before continuing with Google.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    final state = context.read<FarmoraState>();
    final success = await state.registerWithGoogle(
      name: _nameController.text,
      phone: phone,
      role: widget.selectedRole,
      district: _selectedDistrict,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (success) {
      if (_photoBytes != null && _photoFileName != null) {
        await state.uploadProfilePhoto(
          bytes: _photoBytes!,
          fileName: _photoFileName!,
          contentType: _photoContentType ?? 'image/jpeg',
        );
      }
      if (!mounted) return;
      if (widget.onRegistered != null) widget.onRegistered!();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.authError ?? 'Google registration failed.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _togglePhoto() async {
    if (_hasPhoto) {
      setState(() {
        _hasPhoto = false;
        _photoBytes = null;
        _photoFileName = null;
        _photoContentType = null;
      });
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (!mounted || result == null || result.files.single.bytes == null) return;
    final selected = result.files.single;
    final extension = selected.extension?.toLowerCase();
    setState(() {
      _hasPhoto = true;
      _photoBytes = selected.bytes;
      _photoFileName = selected.name;
      _photoContentType = extension == 'png'
          ? 'image/png'
          : extension == 'webp'
              ? 'image/webp'
              : 'image/jpeg';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.forestGreen),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Create Account',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.forestGreen,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Top Selected Role Banner
                _buildRoleBanner(),
                const SizedBox(height: 20),

                // 2. Optional Profile Photo Upload
                _buildPhotoUploader(),
                const SizedBox(height: 24),

                // 3. Card Container for Form Inputs
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.primaryLight,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Field 1: Full Name
                      _buildFieldLabel('Full Name'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: _buildInputDecoration(
                          hintText: 'e.g. Kamal Perera',
                          icon: Icons.person_outline_rounded,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Field 2: Phone Number
                      _buildFieldLabel('Phone Number'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: _buildInputDecoration(
                          hintText: 'e.g. 077 123 4567',
                          icon: Icons.phone_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Field 3: District / Location
                      _buildFieldLabel('District / Location'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedDistrict,
                        hint: const Text(
                          'Select your district',
                          style: TextStyle(
                            color: Colors.black38,
                            fontSize: 15,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.primary,
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        decoration: _buildInputDecoration(
                          hintText: 'Select your district',
                          icon: Icons.location_on_outlined,
                        ),
                        items: _districts.map((d) {
                          return DropdownMenuItem<String>(
                            value: d,
                            child: Text(d),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedDistrict = val);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select your district';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 4. Primary Green Button "Create Account"
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _handleOtpRegister,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 20,
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleRegister,
                    icon: Image.asset('assets/icons/google_g.png',
                        width: 20, height: 20),
                    label: const Text(
                      'Continue with Google',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      foregroundColor: AppColors.forestGreen,
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // 5. Already have an account? Log In Link
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                const Center(
                  child: Text(
                    'By signing up, you agree to Farmora Marketplace Terms',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black38, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Selected Role Context Banner at the top
  Widget _buildRoleBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.selectedRole.icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Joining as ${widget.selectedRole.label}',
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.selectedRole.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const RoleSelectionScreen(),
                ),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              foregroundColor: AppColors.primary,
            ),
            child: const Text(
              'Change',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Optional Profile Photo Uploader Avatar
  Widget _buildPhotoUploader() {
    return Center(
      child: GestureDetector(
        onTap: _togglePhoto,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        _hasPhoto ? AppColors.primaryContainer : Colors.white,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _photoBytes != null
                        ? Image.memory(_photoBytes!, fit: BoxFit.cover)
                        : const Icon(
                            Icons.person_outline_rounded,
                            size: 48,
                            color: AppColors.primary,
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      _hasPhoto ? Icons.check : Icons.camera_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload Photo (Optional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.forestGreen,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Colors.black38,
        fontSize: 15,
        fontWeight: FontWeight.normal,
      ),
      prefixIcon: Icon(
        icon,
        color: AppColors.primary,
        size: 22,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 2,
        ),
      ),
    );
  }
}
