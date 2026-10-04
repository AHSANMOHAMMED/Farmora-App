class HubColdStorageLog {
  final String id;
  final String branchId;
  final String branchName;
  final String roomName; // 'Chamber A - Leafy Veg', 'Chamber B - Root Veg', 'Chamber C - Fruits & Berries'
  final double currentTempC;
  final double targetTempC;
  final double minSafeTempC;
  final double maxSafeTempC;
  final double relativeHumidityPercent;
  final DateTime recordedAt;
  final bool isBreached;
  final String notes;

  const HubColdStorageLog({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.roomName,
    required this.currentTempC,
    required this.targetTempC,
    required this.minSafeTempC,
    required this.maxSafeTempC,
    required this.relativeHumidityPercent,
    required this.recordedAt,
    required this.isBreached,
    this.notes = '',
  });

  bool get isTempNormal =>
      currentTempC >= minSafeTempC && currentTempC <= maxSafeTempC;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'branchId': branchId,
      'branchName': branchName,
      'roomName': roomName,
      'currentTempC': currentTempC,
      'targetTempC': targetTempC,
      'minSafeTempC': minSafeTempC,
      'maxSafeTempC': maxSafeTempC,
      'relativeHumidityPercent': relativeHumidityPercent,
      'recordedAt': recordedAt.toIso8601String(),
      'isBreached': isBreached,
      'notes': notes,
    };
  }

  factory HubColdStorageLog.fromMap(String id, Map<String, dynamic> data) {
    final curTemp = (data['currentTempC'] as num?)?.toDouble() ?? 4.0;
    final minTemp = (data['minSafeTempC'] as num?)?.toDouble() ?? 2.0;
    final maxTemp = (data['maxSafeTempC'] as num?)?.toDouble() ?? 8.0;

    return HubColdStorageLog(
      id: id,
      branchId: data['branchId']?.toString() ?? '',
      branchName: data['branchName']?.toString() ?? '',
      roomName: data['roomName']?.toString() ?? 'Main Cold Chamber',
      currentTempC: curTemp,
      targetTempC: (data['targetTempC'] as num?)?.toDouble() ?? 4.0,
      minSafeTempC: minTemp,
      maxSafeTempC: maxTemp,
      relativeHumidityPercent:
          (data['relativeHumidityPercent'] as num?)?.toDouble() ?? 85.0,
      recordedAt: DateTime.tryParse(data['recordedAt']?.toString() ?? '') ??
          DateTime.now(),
      isBreached: data['isBreached'] == true ||
          curTemp < minTemp ||
          curTemp > maxTemp,
      notes: data['notes']?.toString() ?? '',
    );
  }
}
