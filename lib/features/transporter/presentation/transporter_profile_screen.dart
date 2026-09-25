import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/farmora_state.dart';
import '../../auth/presentation/welcome_screen.dart';
import '../application/transporter_controller.dart';
import 'widgets/transporter_actions.dart';

class TransporterProfileScreen extends StatelessWidget {
  const TransporterProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransporterController>();
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Profile')),
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
              title: const Text('Availability',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(state.isAvailable
                  ? 'Available for new jobs'
                  : 'Unavailable for new jobs'),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading:
                const Icon(Icons.edit_note_rounded, color: AppColors.primary),
            title: const Text('Manage vehicle',
                style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Type, registration and load capacity'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const EditTransporterProfileScreen(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Vehicle information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
                  title: const Text('Vehicle type'),
                  subtitle: Text(state.vehicleType),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading:
                      const Icon(Icons.pin_outlined, color: AppColors.primary),
                  title: const Text('Registration number'),
                  subtitle: Text(state.vehicleRegistration),
                ),
                if (state.vehicleCapacity != null) ...[
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.scale_outlined,
                        color: AppColors.primary),
                    title: const Text('Maximum capacity'),
                    subtitle: Text(
                      '${state.vehicleCapacity!.toStringAsFixed(0)} ${state.vehicleCapacityUnit}',
                    ),
                  ),
                ],
                if (state.vehicleDescription.trim().isNotEmpty) ...[
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.notes_outlined,
                        color: AppColors.primary),
                    title: const Text('Description'),
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
                  title: const Text('Edit profile',
                      style: TextStyle(fontWeight: FontWeight.w700)),
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
                  title: const Text('Logout',
                      style: TextStyle(
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
      title: 'Log out?',
      message: 'You will need to sign in again to manage collection jobs.',
      confirmLabel: 'Log out',
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
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Edit profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_name, 'Full name', Icons.person_outline_rounded),
            const SizedBox(height: 12),
            _field(_phone, 'Phone number', Icons.phone_outlined,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 22),
            const Text(
              'Vehicle information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            _field(_vehicle, 'Vehicle type', Icons.local_shipping_outlined),
            const SizedBox(height: 12),
            _field(_registration, 'Registration number', Icons.pin_outlined),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _capacityUnit,
              decoration: const InputDecoration(
                labelText: 'Capacity unit',
                prefixIcon: Icon(Icons.scale_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'kg', child: Text('Kilograms (kg)')),
                DropdownMenuItem(value: 'tons', child: Text('Tons')),
              ],
              onChanged: (value) =>
                  setState(() => _capacityUnit = value ?? 'kg'),
            ),
            const SizedBox(height: 12),
            _field(_capacity, 'Maximum load capacity',
                Icons.fitness_center_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                )),
            const SizedBox(height: 12),
            _field(_description, 'Vehicle description (optional)',
                Icons.notes_outlined,
                required: false),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save changes'),
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
              ? '$label is required'
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
