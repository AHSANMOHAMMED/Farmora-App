/// Farmer payout account shown to buyers who choose Bank Deposit.
///
/// Stored at `bank_details/{farmerId}` and copied onto each bank-deposit
/// order as `bankDetailsSnapshot` so later edits never change an old order.
class BankDetails {
  final String bankName;
  final String branch;
  final String accountHolderName;
  final String accountNumber;

  const BankDetails({
    required this.bankName,
    required this.branch,
    required this.accountHolderName,
    required this.accountNumber,
  });

  static const empty = BankDetails(
    bankName: '',
    branch: '',
    accountHolderName: '',
    accountNumber: '',
  );

  bool get isComplete =>
      bankName.trim().isNotEmpty &&
      branch.trim().isNotEmpty &&
      accountHolderName.trim().isNotEmpty &&
      isValidAccountNumber(accountNumber);

  /// Sri Lankan account numbers are 6–18 digits; spaces and dashes are ignored.
  static bool isValidAccountNumber(String value) =>
      RegExp(r'^\d{6,18}$').hasMatch(value.replaceAll(RegExp(r'[\s-]'), ''));

  /// "•••• 4521" for list views; the full number is shown only where needed.
  String get maskedAccountNumber {
    final digits = accountNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 4) return digits;
    return '•••• ${digits.substring(digits.length - 4)}';
  }

  Map<String, dynamic> toMap() => {
        'bankName': bankName.trim(),
        'branch': branch.trim(),
        'accountHolderName': accountHolderName.trim(),
        'accountNumber': accountNumber.replaceAll(RegExp(r'[\s-]'), ''),
      };

  factory BankDetails.fromMap(Map<String, dynamic>? data) {
    if (data == null) return empty;
    return BankDetails(
      bankName: (data['bankName'] ?? '').toString(),
      branch: (data['branch'] ?? '').toString(),
      accountHolderName: (data['accountHolderName'] ?? '').toString(),
      accountNumber: (data['accountNumber'] ?? '').toString(),
    );
  }
}
