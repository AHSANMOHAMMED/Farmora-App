import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../providers/farmora_state.dart';
import '../../auth/presentation/welcome_screen.dart';
import '../application/transporter_controller.dart';
import 'widgets/transporter_actions.dart';

class TransporterProfileScreen extends StatelessWidget {
  const TransporterProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransporterController>();
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(l10n.profile)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                _initials(state.profileName),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            state.profileName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            state.phoneNumber,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: AppColors.surfaceContainerLowest,
            child: SwitchListTile(
              value: state.isAvailable,
              onChanged: state.setAvailability,
              secondary: Icon(
                state.isAvailable
                    ? Icons.toggle_on_rounded
                    : Icons.toggle_off_rounded,
                color:
                    state.isAvailable ? AppColors.primary : AppColors.textMuted,
              ),
              title: Text(l10n.availability,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(state.isAvailable
                  ? l10n.transporterAvailableForNewJobs
                  : l10n.transporterUnavailableForNewJobs),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading:
                const Icon(Icons.edit_note_rounded, color: AppColors.primary),
            title: Text(l10n.transporterManageVehicle,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(l10n.transporterManageVehicleHint),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const EditTransporterProfileScreen(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.transporterVehicleInfo,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: AppColors.surfaceContainerLowest,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.local_shipping_outlined,
                      color: AppColors.primary),
                  title: Text(l10n.vehicleType),
                  subtitle: Text(state.vehicleType),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading:
                      const Icon(Icons.pin_outlined, color: AppColors.primary),
                  title: Text(l10n.transporterRegistrationNumber),
                  subtitle: Text(state.vehicleRegistration),
                ),
                if (state.vehicleCapacity != null) ...[
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.scale_outlined,
                        color: AppColors.primary),
                    title: Text(l10n.transporterMaxCapacity),
                    subtitle: Text(
                      l10n.transporterCapacityAmount(
                        AppFormat.number(state.vehicleCapacity!),
                        _unitLabel(l10n, state.vehicleCapacityUnit),
                      ),
                    ),
                  ),
                ],
                if (state.vehicleDescription.trim().isNotEmpty) ...[
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.notes_outlined,
                        color: AppColors.primary),
                    title: Text(l10n.description),
                    subtitle: Text(state.vehicleDescription),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: AppColors.surfaceContainerLowest,
            child: Column(
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.edit_outlined, color: AppColors.primary),
                  title: Text(l10n.editProfile,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const EditTransporterProfileScreen()),
                  ),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading:
                      const Icon(Icons.logout_rounded, color: AppColors.error),
                  title: Text(l10n.logOut,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: AppColors.error)),
                  onTap: () => _logout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _unitLabel(AppLocalizations l10n, String unit) =>
      switch (unit) {
        'tons' => l10n.transporterUnitTons,
        'kg' => l10n.unitKg,
        _ => unit,
      };

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'LP';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await confirmTransporterAction(
      context,
      title: context.l10n.transporterLogoutConfirmTitle,
      message: context.l10n.transporterLogoutConfirmMessage,
      confirmLabel: context.l10n.logOut,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await context.read<FarmoraState>().signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }
}

class EditTransporterProfileScreen extends StatefulWidget {
  const EditTransporterProfileScreen({super.key});

  @override
  State<EditTransporterProfileScreen> createState() =>
      _EditTransporterProfileScreenState();
}

class _EditTransporterProfileScreenState
    extends State<EditTransporterProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _vehicle;
  late final TextEditingController _registration;
  late final TextEditingController _capacity;
  late final TextEditingController _description;
  late String _capacityUnit;

  @override
  void initState() {
    super.initState();
    final state = context.read<TransporterController>();
    _name = TextEditingController(text: state.profileName);
    _phone = TextEditingController(text: state.phoneNumber);
    _vehicle = TextEditingController(text: state.vehicleType);
    _registration = TextEditingController(text: state.vehicleRegistration);
    _capacity = TextEditingController(
      text: state.vehicleCapacity?.toString() ?? '',
    );
    _description = TextEditingController(text: state.vehicleDescription);
    _capacityUnit = state.vehicleCapacityUnit;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _vehicle.dispose();
    _registration.dispose();
    _capacity.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(l10n.editProfile)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(
                _name, l10n.transporterFullName, Icons.person_outline_rounded),
            const SizedBox(height: 12),
            _field(_phone, l10n.transporterPhoneNumber, Icons.phone_outlined,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 22),
            Text(
              l10n.transporterVehicleInfo,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            _field(_vehicle, l10n.vehicleType, Icons.local_shipping_outlined),
            const SizedBox(height: 12),
            _field(_registration, l10n.transporterRegistrationNumber,
                Icons.pin_outlined),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _capacityUnit,
              decoration: InputDecoration(
                labelText: l10n.transporterCapacityUnit,
                prefixIcon: const Icon(Icons.scale_outlined),
              ),
              items: [
                DropdownMenuItem(
                    value: 'kg', child: Text(l10n.transporterUnitKilograms)),
                DropdownMenuItem(
                    value: 'tons', child: Text(l10n.transporterUnitTonsOption)),
              ],
              onChanged: (value) =>
                  setState(() => _capacityUnit = value ?? 'kg'),
            ),
            const SizedBox(height: 12),
            _field(_capacity, l10n.transporterMaxLoadCapacity,
                Icons.fitness_center_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                )),
            const SizedBox(height: 12),
            _field(_description, l10n.transporterVehicleDescriptionOptional,
                Icons.notes_outlined,
                required: false),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(l10n.transporterSaveChanges),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: required
          ? (value) => value == null || value.trim().isEmpty
              ? context.l10n.transporterFieldRequired(label)
              : null
          : null,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final result = await context.read<TransporterController>().updateProfile(
          name: _name.text,
          phone: _phone.text,
          vehicle: _vehicle.text,
          registration: _registration.text,
          capacity: double.tryParse(_capacity.text.trim()),
          capacityUnit: _capacityUnit,
          description: _description.text,
        );
    if (!mounted) return;
    showTransporterResult(context, result);
    if (result.success) Navigator.pop(context);
  }
}
