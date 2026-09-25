import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/bank_details.dart';
import '../../../providers/farmora_state.dart';

/// Farmer's payout account. Buyers see it when they choose Bank Deposit.
class BankDetailsScreen extends StatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bank;
  late final TextEditingController _branch;
  late final TextEditingController _holder;
  late final TextEditingController _account;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final current = context.read<FarmoraState>().myBankDetails;
    _bank = TextEditingController(text: current.bankName);
    _branch = TextEditingController(text: current.branch);
    _holder = TextEditingController(text: current.accountHolderName);
    _account = TextEditingController(text: current.accountNumber);
  }

  @override
  void dispose() {
    _bank.dispose();
    _branch.dispose();
    _holder.dispose();
    _account.dispose();
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<FarmoraState>().saveBankDetails(BankDetails(
            bankName: _bank.text,
            branch: _branch.text,
            accountHolderName: _holder.text,
            accountNumber: _account.text,
          ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Bank details saved. Buyers can now pay by bank deposit.'),
        backgroundColor: AppColors.primary,
      ));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not save bank details: $e'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Bank Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const Text(
              'Buyers who choose Bank Deposit will see these details and '
              'upload their deposit slip in the order chat. Money goes '
              'directly to your account.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _bank,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Bank name',
                hintText: 'e.g. Bank of Ceylon',
                prefixIcon: Icon(Icons.account_balance_outlined),
              ),
              validator: _required,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _branch,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Branch',
                hintText: 'e.g. Nuwara Eliya',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
              validator: _required,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _holder,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Account holder name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: _required,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _account,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Account number',
                prefixIcon: Icon(Icons.numbers),
              ),
              validator: (v) => _required(v) ??
                  (BankDetails.isValidAccountNumber(v!)
                      ? null
                      : 'Enter 6–18 digits'),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save bank details'),
            ),
          ],
        ),
      ),
    );
  }
}
