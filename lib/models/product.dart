import 'package:flutter/material.dart';

enum ProductStatus {
  active,
  empty,
  draft,
}

enum HarvestStatus {
  growing,
  harvested,
  packed,
  inTransit,
  delivered,
}

class Product {
  final String id;
  final String name;
  final String category;
  final String location;
  final String quantity;
  final String unit;
  final String price;
  final double pricePerUnit;
  final String emoji;
  final Color color;
  final String? imagePath;
  final String status;
  final bool isOrganic;
  final String trustLevel;
  final String description;
  final DateTime? availabilityDate;
  final List<String> images;
  final String? videoPath;
  final String? videoUrl;
  final String? qrCode;
  final DateTime? harvestDate;
  final DateTime? packingDate;
  final HarvestStatus harvestStatus;
  final String farmerId;
  // Backend (Cloud Functions) schema fields.
  final int priceMinor;
  final int quantityAvailable;
  final String currency;
  final List<String> media;
  final List<String> imageUrls;
  final List<String> searchTokens;
  final String availability;
  final int listingVersion;

  const Product({
    this.id = '',
    required this.name,
    required this.category,
    required this.location,
    required this.quantity,
    this.unit = 'kg',
    required this.price,
    this.pricePerUnit = 0.0,
    this.emoji = '🌱',
    this.color = const Color(0xFFE8F5E9),
    this.imagePath,
    this.status = 'Active',
    this.isOrganic = false,
    this.trustLevel = 'Standard',
    this.description = '',
    this.availabilityDate,
    this.images = const [],
    this.videoPath,
    this.videoUrl,
    this.qrCode,
    this.harvestDate,
    this.packingDate,
    this.harvestStatus = HarvestStatus.growing,
    this.farmerId = '',
    this.priceMinor = 0,
    this.quantityAvailable = 0,
    this.currency = 'LKR',
    this.media = const [],
    this.imageUrls = const [],
    this.searchTokens = const [],
    this.availability = '',
    this.listingVersion = 1,
  });

  bool get isActive => status.toLowerCase() == 'active';
  bool get isEmpty => status.toLowerCase() == 'empty' || status.toLowerCase() == 'out of stock';
  bool get hasVideo => (videoUrl?.isNotEmpty ?? false) || (videoPath?.isNotEmpty ?? false);
  bool get hasQrCode => (qrCode?.isNotEmpty ?? false);
  double get effectivePricePerUnit => priceMinor > 0 ? priceMinor / 100.0 : pricePerUnit;
  List<String> get allImages {
    final merged = <String>[...images, ...media, ...imageUrls];
    if (imagePath != null && imagePath!.isNotEmpty) merged.insert(0, imagePath!);
    return merged.toSet().toList();
  }
  String? get primaryImage => (imagePath != null && imagePath!.isNotEmpty)
      ? imagePath
      : (allImages.isNotEmpty ? allImages.first : null);

  Product copyWith({
    String? id,
    String? name,
    String? category,
    String? location,
    String? quantity,
    String? unit,
    String? price,
    double? pricePerUnit,
    String? emoji,
    Color? color,
    String? imagePath,
    String? status,
    bool? isOrganic,
    String? trustLevel,
    String? description,
    DateTime? availabilityDate,
    List<String>? images,
    String? videoPath,
    String? videoUrl,
    String? qrCode,
    DateTime? harvestDate,
    DateTime? packingDate,
    HarvestStatus? harvestStatus,
    String? farmerId,
    int? priceMinor,
    int? quantityAvailable,
    String? currency,
    List<String>? media,
    List<String>? imageUrls,
    List<String>? searchTokens,
    String? availability,
    int? listingVersion,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      location: location ?? this.location,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
      imagePath: imagePath ?? this.imagePath,
      status: status ?? this.status,
      isOrganic: isOrganic ?? this.isOrganic,
      trustLevel: trustLevel ?? this.trustLevel,
      description: description ?? this.description,
      availabilityDate: availabilityDate ?? this.availabilityDate,
      images: images ?? this.images,
      videoPath: videoPath ?? this.videoPath,
      videoUrl: videoUrl ?? this.videoUrl,
      qrCode: qrCode ?? this.qrCode,
      harvestDate: harvestDate ?? this.harvestDate,
      packingDate: packingDate ?? this.packingDate,
      harvestStatus: harvestStatus ?? this.harvestStatus,
      farmerId: farmerId ?? this.farmerId,
      priceMinor: priceMinor ?? this.priceMinor,
      quantityAvailable: quantityAvailable ?? this.quantityAvailable,
      currency: currency ?? this.currency,
      media: media ?? this.media,
      imageUrls: imageUrls ?? this.imageUrls,
      searchTokens: searchTokens ?? this.searchTokens,
      availability: availability ?? this.availability,
      listingVersion: listingVersion ?? this.listingVersion,
    );
  }

  /// Positional factory constructor for backward compatibility with existing tests
  factory Product.positional(
    String name,
    String category,
    String location,
    String quantity,
    String price,
    String emoji,
    Color color, {
    String id = '',
    String trustLevel = 'Standard',
  }) {
    return Product(
      id: id,
      name: name,
      category: category,
      location: location,
      quantity: quantity,
      price: price,
      emoji: emoji,
      color: color,
      trustLevel: trustLevel,
    );
  }

  /// Serialize to Firestore-compatible Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'location': location,
      'quantity': quantity,
      'unit': unit,
      'price': price,
      'pricePerUnit': pricePerUnit,
      'emoji': emoji,
      'color': color.toARGB32(),
      'imagePath': imagePath,
      'status': status,
      'isOrganic': isOrganic,
      'trustLevel': trustLevel,
      'description': description,
      'availabilityDate': availabilityDate?.toIso8601String(),
      'images': images,
      'videoPath': videoPath,
      'videoUrl': videoUrl,
      'qrCode': qrCode,
      'harvestDate': harvestDate?.toIso8601String(),
      'packingDate': packingDate?.toIso8601String(),
      'harvestStatus': harvestStatus.name,
      'farmerId': farmerId,
      'priceMinor': priceMinor,
      'quantityAvailable': quantityAvailable,
      'currency': currency,
      'media': media,
      'imageUrls': imageUrls,
      'searchTokens': searchTokens,
      'availability': availability,
      'listingVersion': listingVersion,
    };
  }

  /// Deserialize from Firestore Map
  factory Product.fromMap(String id, Map<String, dynamic> data) {
    final priceMinor = (data['priceMinor'] as num?)?.toInt() ?? 0;
    final legacyPrice = (data['pricePerUnit'] as num?)?.toDouble() ?? 0.0;
    final media = List<String>.from(data['media'] ?? []);
    final imageUrls = List<String>.from(data['imageUrls'] ?? []);
    final legacyImages = List<String>.from(data['images'] ?? []);
    final mergedImages = {...legacyImages, ...media, ...imageUrls}.toList();
    return Product(
      id: id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      location: data['location'] ?? '',
      quantity: (data['quantity'] ?? data['quantityAvailable']?.toString() ?? '').toString(),
      unit: data['unit'] ?? 'kg',
      price: (data['price'] ?? '').toString(),
      pricePerUnit: priceMinor > 0 ? priceMinor / 100.0 : legacyPrice,
      emoji: data['emoji'] ?? '🌱',
      color: Color(data['color'] as int? ?? 0xFFE8F5E9),
      imagePath: (data['imagePath'] as String?)?.isNotEmpty == true
          ? (data['imagePath'] as String)
          : (mergedImages.isNotEmpty ? mergedImages.first : null),
      status: data['status'] ?? 'Active',
      isOrganic: data['isOrganic'] ?? true,
      description: data['description'] ?? '',
      availabilityDate: data['availabilityDate'] != null
          ? DateTime.tryParse(data['availabilityDate'] as String)
          : null,
      images: mergedImages,
      trustLevel: data['trustLevel'] ?? 'Standard',
      priceMinor: priceMinor,
      quantityAvailable: (data['quantityAvailable'] as num?)?.toInt() ?? 0,
      currency: (data['currency'] ?? 'LKR').toString(),
      media: media,
      imageUrls: imageUrls,
      searchTokens: List<String>.from(data['searchTokens'] ?? []),
      availability: (data['availability'] ?? '').toString(),
      listingVersion: (data['listingVersion'] as num?)?.toInt() ?? 1,
      videoPath: data['videoPath'] as String?,
      videoUrl: data['videoUrl'] as String?,
      qrCode: data['qrCode'] as String?,
      harvestDate: data['harvestDate'] != null
          ? DateTime.tryParse(data['harvestDate'].toString())
          : null,
      packingDate: data['packingDate'] != null
          ? DateTime.tryParse(data['packingDate'].toString())
          : null,
      harvestStatus: HarvestStatus.values.firstWhere(
        (e) => e.name == (data['harvestStatus'] ?? 'growing'),
        orElse: () => HarvestStatus.growing,
      ),
      farmerId: data['farmerId'] ?? '',
    );
  }
}
