import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';

import '../../../core/constants/app_colors.dart';
import '../../../providers/farmora_state.dart';
import '../../../services/firebase_service.dart';

/// Edit profile screen for Farmer/Buyer accounts.
/// Supports editing display name and district, and uploading a profile photo.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _selectedDistrict;
  bool _saving = false;

  final _picker = ImagePicker();
  Uint8List? _photoBytes;
  String? _photoName;
  String? _photoContentType;

  static const List<String> _districts = [
    'Ampara', 'Anuradhapura', 'Badulla', 'Batticaloa', 'Colombo', 'Galle',
    'Gampaha', 'Hambantota', 'Jaffna', 'Kalutara', 'Kandy', 'Kegalle',
    'Kilinochchi', 'Kurunegala', 'Mannar', 'Matale', 'Matara', 'Monaragala',
    'Mullaitivu', 'Nuwara Eliya', 'Polonnaruwa', 'Puttalam', 'Ratnapura',
    'Trincomalee', 'Vavuniya',
  ];

  @override
  void initState() {
    super.initState();
    final state = context.read<FarmoraState>();
    _nameController = TextEditingController(text: state.displayName);
    _selectedDistrict =
        _districts.contains(state.district) ? state.district : _districts.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_saving) return;
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _photoBytes = bytes;
        _photoName = file.name;
        _photoContentType = file.mimeType ?? 'image/jpeg';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick photo: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_saving) return;
    setState(() => _saving = true);

    final state = context.read<FarmoraState>();
    try {
      // Upload new photo first (optional).
      if (_photoBytes != null && _photoName != null) {
        try {
          final url = await FirestoreService().uploadProfilePhoto(
            bytes: _photoBytes!,
            fileName: _photoName!,
            contentType: _photoContentType ?? 'image/jpeg',
          );
          await state.updateProfile(photoUrl: url);
        } catch (e) {
          // Photo upload is optional; keep saving the rest.
          debugPrint('Profile photo upload note: $e');
        }
      }

      await state.updateProfile(
        name: _nameController.text,
        newDistrict: _selectedDistrict,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final avatarUrl = _photoBytes != null
        ? null
        : (state.photoUrl.isNotEmpty ? state.photoUrl : null);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: ClipOval(
                      child: _photoBytes != null
                          ? Image.memory(_photoBytes!,
                              fit: BoxFit.cover)
                          : (avatarUrl != null
                              ? Image.network(avatarUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.person,
                                          size: 48,
                                          color: AppColors.primary))
                              : const Icon(Icons.person,
                                  size: 48, color: AppColors.primary)),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _pickPhoto,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Change photo'),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Name is required'
                      : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedDistrict,
              decoration: const InputDecoration(
                labelText: 'District',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              items: _districts
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _selectedDistrict = value ?? _selectedDistrict),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Saving...' : 'Save changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
