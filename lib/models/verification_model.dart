import 'package:flutter/material.dart';

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
  });

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
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      icon: iconData,
      status: statusVal,
      fileName: data['fileName'] as String?,
      fileSizeInfo: data['fileSizeInfo'] as String?,
      imagePreview: data['imagePreview'] as String?,
      errorMessage: data['errorMessage'] as String?,
      hasFrontBack: data['hasFrontBack'] ?? false,
      frontImage: data['frontImage'] as String?,
      backImage: data['backImage'] as String?,
    );
  }
}
