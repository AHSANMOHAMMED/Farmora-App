import 'package:flutter/material.dart';

import '../core/localization/l10n.dart';
import '../core/utils/firebase_values.dart';

enum VerificationStatus {
  pending,
  approved,
  rejected,
}

class VerificationDoc {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final VerificationStatus status;
  final String? fileName;
  final String? fileSizeInfo;
  final String? imagePreview;
  final String? errorMessage;
  final bool hasFrontBack;
  final String? frontImage;
  final String? backImage;

  /// Admin's reason when rejected (`rejectionReason`, legacy `errorMessage`).
  final String? rejectionReason;

  /// Firebase Storage path of the uploaded file.
  final String? storagePath;

  /// Uid of the user the document belongs to (`ownerId`, legacy `farmerId`).
  final String? ownerId;
  final DateTime? createdAt;

  const VerificationDoc({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.status,
    this.fileName,
    this.fileSizeInfo,
    this.imagePreview,
    this.errorMessage,
    this.hasFrontBack = false,
    this.frontImage,
    this.backImage,
    this.rejectionReason,
    this.storagePath,
    this.ownerId,
    this.createdAt,
  });

  /// [title] in the app language when it is a known document type (stored
  /// values stay English); otherwise the stored text.
  String get displayTitle => documentTypeLabel(title);

  /// [description] for display. A bare storage path is replaced with a short
  /// localized note.
  String get displayDescription {
    final d = description.trim();
    if (d.startsWith('verification/')) {
      return L10n.current.svcDocUploadedForReview;
    }
    return description;
  }

  /// Display name for a stored document type such as `NIC` or
  /// `Vehicle Registration`. Unknown values are returned unchanged.
  static String documentTypeLabel(String raw, [AppLocalizations? l10n]) {
    final l = l10n ?? L10n.current;
    final n = raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
    bool has(String w) => n.split(' ').contains(w);
    if (n.isEmpty) return raw;
    if (n == 'document' || n == 'doc') return l.svcDocGeneric;
    if (has('nic') || n.contains('national id')) return l.svcDocNationalId;
    if (n.contains('land')) return l.svcDocLandOwnership;
    if (n.contains('driving') || n.contains('driver')) {
      return l.svcDocDrivingLicence;
    }
    if (n.contains('insurance')) return l.svcDocVehicleInsurance;
    if (n.contains('vehicle') || n.contains('revenue licen')) {
      return l.svcDocVehicleRegistration;
    }
    if (has('bank') || n.contains('passbook')) return l.svcDocBankProof;
    if (n.contains('farm') && n.contains('photo')) return l.svcDocFarmPhoto;
    if (n.contains('agrarian') || n.contains('farmer registration')) {
      return l.svcDocFarmerRegistration;
    }
    if (n.contains('business') || has('br')) {
      return l.svcDocBusinessRegistration;
    }
    return raw;
  }

  VerificationDoc copyWith({
    String? id,
    String? title,
    String? description,
    IconData? icon,
    VerificationStatus? status,
    String? fileName,
    String? fileSizeInfo,
    String? imagePreview,
    String? errorMessage,
    bool? hasFrontBack,
    String? frontImage,
    String? backImage,
    String? rejectionReason,
    String? storagePath,
    String? ownerId,
    DateTime? createdAt,
  }) {
    return VerificationDoc(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      status: status ?? this.status,
      fileName: fileName ?? this.fileName,
      fileSizeInfo: fileSizeInfo ?? this.fileSizeInfo,
      imagePreview: imagePreview ?? this.imagePreview,
      errorMessage: errorMessage ?? this.errorMessage,
      hasFrontBack: hasFrontBack ?? this.hasFrontBack,
      frontImage: frontImage ?? this.frontImage,
      backImage: backImage ?? this.backImage,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      storagePath: storagePath ?? this.storagePath,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Serialize to Firestore-compatible Map
  Map<String, dynamic> toMap() {
    // Map IconData to string key
    String iconKey = 'badge';
    if (icon == Icons.description_outlined) iconKey = 'description';
    if (icon == Icons.directions_car_outlined) iconKey = 'directions_car';
    if (icon == Icons.local_shipping_outlined) iconKey = 'local_shipping';

    // Map VerificationStatus to string
    String statusKey = 'pending';
    if (status == VerificationStatus.approved) statusKey = 'approved';
    if (status == VerificationStatus.rejected) statusKey = 'rejected';

    return {
      'title': title,
      'description': description,
      'icon': iconKey,
      'status': statusKey,
      'fileName': fileName,
      'fileSizeInfo': fileSizeInfo,
      'imagePreview': imagePreview,
      'errorMessage': errorMessage,
      'hasFrontBack': hasFrontBack,
      'frontImage': frontImage,
      'backImage': backImage,
    };
  }

  /// Deserialize from Firestore Map
  factory VerificationDoc.fromMap(String id, Map<String, dynamic> data) {
    // Map string key back to IconData
    IconData iconData = Icons.badge_outlined;
    switch (data['icon']) {
      case 'description':
        iconData = Icons.description_outlined;
        break;
      case 'directions_car':
        iconData = Icons.directions_car_outlined;
        break;
      case 'local_shipping':
        iconData = Icons.local_shipping_outlined;
        break;
    }

    // Map string back to VerificationStatus
    VerificationStatus statusVal = VerificationStatus.pending;
    switch (data['status']) {
      case 'approved':
        statusVal = VerificationStatus.approved;
        break;
      case 'rejected':
        statusVal = VerificationStatus.rejected;
        break;
    }

    return VerificationDoc(
      id: id,
      title: (data['title'] ?? data['documentType'] ?? '').toString(),
      description:
          (data['description'] ?? data['storagePath'] ?? '').toString(),
      icon: iconData,
      status: statusVal,
      fileName: data['fileName'] as String? ?? data['storagePath'] as String?,
      fileSizeInfo: data['fileSizeInfo'] as String?,
      imagePreview: data['imagePreview'] as String?,
      errorMessage: data['errorMessage'] as String?,
      hasFrontBack: data['hasFrontBack'] ?? false,
      frontImage: data['frontImage'] as String?,
      backImage: data['backImage'] as String?,
      rejectionReason: _optString(data['rejectionReason']) ??
          _optString(data['errorMessage']),
      storagePath: _optString(data['storagePath']),
      ownerId: _optString(data['ownerId']) ?? _optString(data['farmerId']),
      createdAt: firebaseDate(data['createdAt']),
    );
  }

  static String? _optString(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }
}
