import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../providers/farmora_state.dart';
import '../../auth/presentation/auth_gate.dart';
import '../../farmer/presentation/account_verification_screen.dart';
import '../application/transporter_controller.dart';
import 'transporter_payouts_screen.dart';
import 'widgets/transporter_actions.dart';

class TransporterProfileScreen extends StatelessWidget {
  const TransporterProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransporterController>();
    final isVerified = context.select<FarmoraState, bool>((s) => s.isVerified);
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
              onChanged: (value) async {
                final result = await state.setAvailability(value);
                if (context.mounted) showTransporterResult(context, result);
              },
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
          if (!isVerified) ...[
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: AppColors.surfaceContainerLowest,
              child: ListTile(
                leading: const Icon(Icons.verified_user_outlined,
                    color: AppColors.statusPendingText),
                title: Text(l10n.profileVerification,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(l10n.verifyTransporterHint),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AccountVerificationScreen(),
                  ),
                ),
              ),
            ),
          ],
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
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.map_outlined,
                      color: AppColors.primary),
                  title: const Text('Service districts'),
                  subtitle: Text(state.serviceDistricts.isEmpty
                      ? 'Not set (jobs from all districts are shown)'
                      : state.serviceDistricts.join(', ')),
                ),
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
                  leading: const Icon(Icons.payments_outlined,
                      color: AppColors.primary),
                  title: Text(l10n.earnings,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Request withdrawals and view payouts'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const TransporterPayoutsScreen()),
                  ),
                ),
                const Divider(height: 1, indent: 56),
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
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final appState = context.read<FarmoraState>();
    final controller = context.read<TransporterController>();
    final providerId = controller.providerId;
    controller.unbind();
    try {
      await appState.signOut();
    } catch (error) {
      // Still signed in: restore the transporter's live data.
      if (providerId.isNotEmpty) controller.bindProvider(providerId);
      messenger.showSnackBar(SnackBar(
        content: Text(userMessage(error, action: 'sign out')),
        backgroundColor: errorColor,
      ));
      return;
    }
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
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
  late final TextEditingController _districts;
  late String _capacityUnit;
  bool _saving = false;

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
    _districts =
        TextEditingController(text: state.serviceDistricts.join(', '));
    _capacityUnit = state.vehicleCapacityUnit == 'tons' ? 'tons' : 'kg';
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _vehicle.dispose();
    _registration.dispose();
    _capacity.dispose();
    _description.dispose();
    _districts.dispose();
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
            TextFormField(
              controller: _capacity,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.transporterMaxLoadCapacity,
                prefixIcon: const Icon(Icons.fitness_center_outlined),
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) {
                  return l10n.transporterFieldRequired(
                      l10n.transporterMaxLoadCapacity);
                }
                final parsed = double.tryParse(text);
                if (parsed == null || parsed <= 0) {
                  return 'Enter a valid capacity.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _districts,
              decoration: const InputDecoration(
                labelText: 'Service districts',
                helperText: 'Comma separated, e.g. Colombo, Gampaha. '
                    'Used by the suitable-jobs filter.',
                helperMaxLines: 2,
                prefixIcon: Icon(Icons.map_outlined),
              ),
            ),
            const SizedBox(height: 12),
            _field(_description, l10n.transporterVehicleDescriptionOptional,
                Icons.notes_outlined,
                required: false),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
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
    setState(() => _saving = true);
    final districts = _districts.text
        .split(',')
        .map((d) => d.trim())
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList();
    final result = await context.read<TransporterController>().updateProfile(
          name: _name.text,
          phone: _phone.text,
          vehicle: _vehicle.text,
          registration: _registration.text,
          capacity: double.tryParse(_capacity.text.trim()),
          capacityUnit: _capacityUnit,
          description: _description.text,
          districts: districts,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    showTransporterResult(context, result);
    if (result.success) Navigator.pop(context);
  }
}
