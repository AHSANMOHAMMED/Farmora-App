import '../core/utils/firebase_values.dart';

class AuditLog {
  final String id;
  final String actorId;
  final String actorName;
  final String actorRole;
  final String actionType; // e.g. ESCROW_RELEASE, USER_SUSPENDED, MAINTENANCE_TOGGLE
  final String targetEntity; // e.g. Order, User, PlatformSettings, Review
  final String targetId;
  final String details;
  final String severity; // info, warning, critical
  final DateTime timestamp;
  final String? ipAddress;

  const AuditLog({
    required this.id,
    required this.actorId,
    required this.actorName,
    required this.actorRole,
    required this.actionType,
    required this.targetEntity,
    required this.targetId,
    required this.details,
    required this.severity,
    required this.timestamp,
    this.ipAddress,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'actorId': actorId,
      'actorName': actorName,
      'actorRole': actorRole,
      'actionType': actionType,
      'targetEntity': targetEntity,
      'targetId': targetId,
      'details': details,
      'severity': severity,
      'timestamp': timestamp.toIso8601String(),
      if (ipAddress != null) 'ipAddress': ipAddress,
    };
  }

  factory AuditLog.fromMap(Map<String, dynamic> map, [String? docId]) {
    return AuditLog(
      id: docId ?? (map['id'] ?? '').toString(),
      actorId: (map['actorId'] ?? '').toString(),
      actorName: (map['actorName'] ?? 'System Admin').toString(),
      actorRole: (map['actorRole'] ?? 'admin').toString(),
      actionType: (map['actionType'] ?? 'UNKNOWN').toString(),
      targetEntity: (map['targetEntity'] ?? 'System').toString(),
      targetId: (map['targetId'] ?? '').toString(),
      details: (map['details'] ?? '').toString(),
      severity: (map['severity'] ?? 'info').toString(),
      timestamp: firebaseDate(map['timestamp']) ?? DateTime.now(),
      ipAddress: map['ipAddress']?.toString(),
    );
  }

  AuditLog copyWith({
    String? id,
    String? actorId,
    String? actorName,
    String? actorRole,
    String? actionType,
    String? targetEntity,
    String? targetId,
    String? details,
    String? severity,
    DateTime? timestamp,
    String? ipAddress,
  }) {
    return AuditLog(
      id: id ?? this.id,
      actorId: actorId ?? this.actorId,
      actorName: actorName ?? this.actorName,
      actorRole: actorRole ?? this.actorRole,
      actionType: actionType ?? this.actionType,
      targetEntity: targetEntity ?? this.targetEntity,
      targetId: targetId ?? this.targetId,
      details: details ?? this.details,
      severity: severity ?? this.severity,
      timestamp: timestamp ?? this.timestamp,
      ipAddress: ipAddress ?? this.ipAddress,
    );
  }
}
