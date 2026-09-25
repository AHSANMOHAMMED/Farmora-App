import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
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
      (v == null || v.trim().isEmpty) ? context.l10n.commonRequired : null;

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.l10n.bankSaved),
        backgroundColor: AppColors.primary,
      ));
      Navigator.of(context).pop();
    } catch (e, st) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.l10n.bankSaveFailed(
            userMessage(e, action: 'save bank details', stack: st))),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(l.bankDetailsTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              l.bankIntro,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _bank,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l.bankNameLabel,
                hintText: l.bankNameHint,
                prefixIcon: const Icon(Icons.account_balance_outlined),
              ),
              validator: _required,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _branch,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l.bankBranchLabel,
                hintText: l.bankBranchHint,
                prefixIcon: const Icon(Icons.location_city_outlined),
              ),
              validator: _required,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _holder,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l.bankHolderLabel,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              validator: _required,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _account,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l.bankAccountNumberLabel,
                prefixIcon: const Icon(Icons.numbers),
              ),
              validator: (v) => _required(v) ??
                  (BankDetails.isValidAccountNumber(v!)
                      ? null
                      : l.bankAccountDigits),
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
                  : Text(l.bankSaveButton),
            ),
          ],
        ),
      ),
    );
  }
}
