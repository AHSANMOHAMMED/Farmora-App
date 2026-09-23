class SettlementPayout {
  final String id;
  final String orderId;
  final String orderNumber;
  final String recipientId;
  final String recipientName;
  final String recipientRole; // farmer, transporter
  final String bankName; // Commercial Bank, Bank of Ceylon, HNB, Sampath Bank, eZ Cash
  final String accountNumber;
  final double grossAmount;
  final double platformFee;
  final double netAmount;
  final String payoutMethod; // CEFT, SLIP, Mobile Wallet
  final String status; // pending, processing, settled, on_hold
  final DateTime createdAt;
  final DateTime? settledAt;
  final String? transactionReference;
  final String? holdReason;

  const SettlementPayout({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.recipientId,
    required this.recipientName,
    required this.recipientRole,
    required this.bankName,
    required this.accountNumber,
    required this.grossAmount,
    required this.platformFee,
    required this.netAmount,
    required this.payoutMethod,
    required this.status,
    required this.createdAt,
    this.settledAt,
    this.transactionReference,
    this.holdReason,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'orderNumber': orderNumber,
      'recipientId': recipientId,
      'recipientName': recipientName,
      'recipientRole': recipientRole,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'grossAmount': grossAmount,
      'platformFee': platformFee,
      'netAmount': netAmount,
      'payoutMethod': payoutMethod,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      if (settledAt != null) 'settledAt': settledAt!.toIso8601String(),
      if (transactionReference != null) 'transactionReference': transactionReference,
      if (holdReason != null) 'holdReason': holdReason,
    };
  }

  factory SettlementPayout.fromMap(Map<String, dynamic> map, [String? docId]) {
    return SettlementPayout(
      id: docId ?? (map['id'] ?? '').toString(),
      orderId: (map['orderId'] ?? '').toString(),
      orderNumber: (map['orderNumber'] ?? '').toString(),
      recipientId: (map['recipientId'] ?? '').toString(),
      recipientName: (map['recipientName'] ?? 'Beneficiary').toString(),
      recipientRole: (map['recipientRole'] ?? 'farmer').toString(),
      bankName: (map['bankName'] ?? 'Commercial Bank of Ceylon').toString(),
      accountNumber: (map['accountNumber'] ?? 'XXXX-XXXX-XXXX').toString(),
      grossAmount: (map['grossAmount'] as num?)?.toDouble() ?? 0.0,
      platformFee: (map['platformFee'] as num?)?.toDouble() ?? 0.0,
      netAmount: (map['netAmount'] as num?)?.toDouble() ?? 0.0,
      payoutMethod: (map['payoutMethod'] ?? 'CEFT').toString(),
      status: (map['status'] ?? 'pending').toString(),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      settledAt: map['settledAt'] != null
          ? DateTime.tryParse(map['settledAt'].toString())
          : null,
      transactionReference: map['transactionReference']?.toString(),
      holdReason: map['holdReason']?.toString(),
    );
  }

  SettlementPayout copyWith({
    String? id,
    String? orderId,
    String? orderNumber,
    String? recipientId,
    String? recipientName,
    String? recipientRole,
    String? bankName,
    String? accountNumber,
    double? grossAmount,
    double? platformFee,
    double? netAmount,
    String? payoutMethod,
    String? status,
    DateTime? createdAt,
    DateTime? settledAt,
    String? transactionReference,
    String? holdReason,
    bool clearHoldReason = false,
  }) {
    return SettlementPayout(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      orderNumber: orderNumber ?? this.orderNumber,
      recipientId: recipientId ?? this.recipientId,
      recipientName: recipientName ?? this.recipientName,
      recipientRole: recipientRole ?? this.recipientRole,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      grossAmount: grossAmount ?? this.grossAmount,
      platformFee: platformFee ?? this.platformFee,
      netAmount: netAmount ?? this.netAmount,
      payoutMethod: payoutMethod ?? this.payoutMethod,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      settledAt: settledAt ?? this.settledAt,
      transactionReference: transactionReference ?? this.transactionReference,
      holdReason: clearHoldReason ? null : (holdReason ?? this.holdReason),
    );
  }
}
