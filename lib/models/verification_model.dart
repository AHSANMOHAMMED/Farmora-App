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
}
