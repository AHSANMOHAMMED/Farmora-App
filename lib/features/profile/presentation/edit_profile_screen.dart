import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/image_upload.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/user_role.dart';
import '../../../providers/farmora_state.dart';
import '../../auth/presentation/auth_l10n.dart';

/// Edit profile screen for Farmer/Buyer accounts: photo, name, district and,
/// for farmers, farm details. Phone is shown read-only (it is the sign-in id).
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _maxName = 120;
  static const _maxFarmName = 80;
  static const _maxFarmSize = 40;
  static const _maxCrops = 10;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _farmNameController;
  late final TextEditingController _farmSizeController;
  late final TextEditingController _cropsController;
  String? _selectedDistrict;
  bool _saving = false;
  PickedImage? _photo;

  static const List<String> _districts = sriLankaDistricts;

  @override
  void initState() {
    super.initState();
    final state = context.read<FarmoraState>();
    _nameController = TextEditingController(text: state.displayName);
    _farmNameController = TextEditingController(text: state.farmName);
    _farmSizeController = TextEditingController(text: state.farmSize);
    _cropsController = TextEditingController(text: state.mainCrops.join(', '));
    _selectedDistrict =
        _districts.contains(state.district) ? state.district : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _farmNameController.dispose();
    _farmSizeController.dispose();
    _cropsController.dispose();
    super.dispose();
  }

  List<String> get _crops => _cropsController.text
      .split(',')
      .map((c) => c.trim())
      .where((c) => c.isNotEmpty)
      .toList();

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.error,
    ));
  }

  Future<void> _pickPhoto() async {
    if (_saving) return;
    final l = AppLocalizations.of(context);
    try {
      final image = await ImagePickerHelper().pickOne();
      if (image == null || !mounted) return;
      setState(() => _photo = image);
    } catch (e) {
      debugPrint('Profile photo pick failed: $e');
      if (mounted) _showError(l.editProfilePhotoPickFailed);
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final l = AppLocalizations.of(context);
    final state = context.read<FarmoraState>();
    final isFarmer = state.role == Role.farmer;
    setState(() => _saving = true);

    try {
      if (_photo != null && state.currentUserId.isNotEmpty) {
        try {
          await state.changeProfilePhoto(_photo!);
        } catch (e) {
          debugPrint('Profile photo upload failed: $e');
          if (mounted) _showError(l.profilePhotoFailed);
          return;
        }
      }

      await state.updateProfile(
        name: _nameController.text,
        newDistrict: _selectedDistrict,
        farmName: isFarmer ? _farmNameController.text : null,
        farmSize: isFarmer ? _farmSizeController.text : null,
        mainCrops: isFarmer ? _crops : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l.profileUpdatedSuccessfully),
        backgroundColor: AppColors.primary,
      ));
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Profile save failed: $e');
      if (mounted) _showError(l.editProfileSaveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _maxLength(String? value, int max) {
    if ((value ?? '').trim().length > max) {
      return AppLocalizations.of(context).editProfileTooLong(max);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = context.watch<FarmoraState>();
    final isFarmer = state.role == Role.farmer;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(l.editProfile)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Center(child: _buildAvatar(state)),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _saving ? null : _pickPhoto,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: Text(l.changePhoto),
              ),
            ),
            const SizedBox(height: 16),
            _FormCard(
              title: l.editProfilePersonal,
              children: [
                TextFormField(
                  controller: _nameController,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l.editProfileFullName,
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? l.editProfileNameRequired
                      : _maxLength(value, _maxName),
                ),
                if (state.phone.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: state.phone,
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: l.editProfilePhone,
                      helperText: l.editProfilePhoneLocked,
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedDistrict,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l.editProfileDistrict,
                    prefixIcon: const Icon(Icons.location_on_outlined),
                  ),
                  items: _districts
                      .map((d) => DropdownMenuItem(
                          value: d, child: Text(districtLabel(d, l))))
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _selectedDistrict = value),
                ),
              ],
            ),
            if (isFarmer) ...[
              const SizedBox(height: 16),
              _FormCard(
                title: l.editProfileFarmSection,
                children: [
                  TextFormField(
                    controller: _farmNameController,
                    enabled: !_saving,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l.editProfileFarmName,
                      prefixIcon: const Icon(Icons.grass_rounded),
                    ),
                    validator: (v) => _maxLength(v, _maxFarmName),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _farmSizeController,
                    enabled: !_saving,
                    decoration: InputDecoration(
                      labelText: l.editProfileFarmSize,
                      hintText: l.editProfileFarmSizeHint,
                      prefixIcon: const Icon(Icons.straighten_rounded),
                    ),
                    validator: (v) => _maxLength(v, _maxFarmSize),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cropsController,
                    enabled: !_saving,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l.editProfileMainCrops,
                      hintText: l.editProfileMainCropsHint,
                      prefixIcon: const Icon(Icons.spa_outlined),
                    ),
                    validator: (_) =>
                        _crops.length > _maxCrops ? l.editProfileTooManyCrops : null,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
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
              label: Text(_saving ? l.editProfileSaving : l.editProfileSave),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(FarmoraState state) {
    const fallback = Icon(Icons.person, size: 48, color: AppColors.primary);
    final Widget image = _photo != null
        ? Image.memory(_photo!.bytes, fit: BoxFit.cover)
        : state.photoUrl.isNotEmpty
            ? Image.network(state.photoUrl,
                fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback)
            : fallback;
    return InkWell(
      onTap: _pickPhoto,
      customBorder: const CircleBorder(),
      child: Stack(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: ClipOval(child: image),
          ),
          Positioned(
            bottom: 0,
            right: 0,
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
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _FormCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
