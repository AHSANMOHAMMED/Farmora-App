import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../core/utils/image_upload.dart';
import '../../../core/widgets/safe_image.dart';
import '../../../models/product.dart';
import '../../../providers/farmora_state.dart';
import '../../../services/firebase_service.dart';
import '../../../core/constants/demo_catalog_data.dart';
import '../../auth/presentation/auth_l10n.dart' show districtLabel;
import 'farmer_l10n.dart';

class AddProductScreen extends StatefulWidget {
  final Product? existingProduct;

  const AddProductScreen({
    super.key,
    this.existingProduct,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final _firestore = FirestoreService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _category = 'Vegetables';
  String _unit = 'kg';
  String _district = 'Nuwara Eliya';
  bool _isOrganic = false;
  DateTime? _availabilityDate = DateTime.now().add(const Duration(days: 1));

  static const List<String> _districts = [
    'Nuwara Eliya',
    'Dambulla',
    'Kandy',
    'Badulla',
    'Jaffna',
    'Anuradhapura',
    'Matale',
    'Kurunegala',
    'Colombo',
    'Gampaha',
    'Kalutara',
    'Galle',
    'Matara',
    'Hambantota',
    'Puttalam',
    'Polonnaruwa',
    'Ratnapura',
    'Kegalle',
    'Monaragala',
    'Batticaloa',
    'Ampara',
    'Trincomalee',
    'Vavuniya',
    'Mannar',
    'Kilinochchi',
    'Mullaitivu',
  ];

  static const _maxImages = 5;
  final _imagePicker = ImagePickerHelper();

  /// Photos in display order: existing URLs and newly picked local images.
  final List<_ImageSlot> _images = [];

  /// URLs the product had when the screen opened (edit mode).
  final Set<String> _originalUrls = {};
  bool _isSubmitting = false;
  bool _isPicking = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingProduct != null) {
      final p = widget.existingProduct!;
      _nameController.text = p.name;
      final qtyMatch = RegExp(r'^([\d.]+)\s').firstMatch(p.quantity);
      _quantityController.text = qtyMatch != null
          ? qtyMatch.group(1)!
          : (p.quantityAvailable > 0 ? '${p.quantityAvailable}' : '');
      _priceController.text = p.pricePerUnit.toString();
      _descriptionController.text = p.description;
      _category = p.category;
      _unit = p.unit;
      if (p.location.isNotEmpty && _districts.contains(p.location)) {
        _district = p.location;
      }
      _isOrganic = p.isOrganic;
      _availabilityDate = p.availabilityDate;
      final existingMedia = [
        ...p.media,
        ...p.imageUrls,
        ...p.images,
      ].where((u) => u.isNotEmpty).toSet().toList();
      for (final url in existingMedia.take(_maxImages)) {
        _images.add(_ImageSlot.remote(url));
        _originalUrls.add(url);
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final stateDistrict = context.read<FarmoraState>().district.trim();
        if (stateDistrict.isNotEmpty && _districts.contains(stateDistrict)) {
          setState(() => _district = stateDistrict);
        }
      });
    }
  }

  @override
  void dispose() {
    // Photos uploaded during an attempt that was never saved would be
    // orphaned in Storage; remove them (best effort).
    if (!_saved) {
      for (final slot in _images) {
        if (slot.local != null && slot.uploadedUrl != null) {
          _firestore.deleteOwnProductImage(slot.uploadedUrl!);
        }
      }
    }
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _availabilityDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _availabilityDate = picked);
  }

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.error : null,
      behavior: SnackBarBehavior.floating,
    ));
  }

  /// Picks new photos for preview. Nothing is uploaded until Save.
  Future<void> _pickImages() async {
    if (_images.length >= _maxImages || _isPicking || _isSubmitting) return;
    setState(() => _isPicking = true);
    final rejected = <String>[];
    try {
      final picked = await _imagePicker.pickMany(
        limit: _maxImages - _images.length,
        rejected: rejected.add,
      );
      if (!mounted) return;
      if (picked.isNotEmpty) {
        setState(() => _images.addAll(picked.map(_ImageSlot.local)));
      }
      if (rejected.isNotEmpty) _showSnack(rejected.join('\n'), error: true);
    } catch (e, st) {
      _showSnack(userMessage(e, action: 'add photos', stack: st), error: true);
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  /// Replaces the photo at [index] with a newly picked one.
  Future<void> _replaceImage(int index) async {
    if (_isPicking || _isSubmitting) return;
    setState(() => _isPicking = true);
    try {
      final picked = await _imagePicker.pickOne();
      if (picked == null || !mounted) return;
      final old = _images[index];
      if (old.local != null && old.uploadedUrl != null) {
        _firestore.deleteOwnProductImage(old.uploadedUrl!);
      }
      setState(() => _images[index] = _ImageSlot.local(picked));
    } catch (e, st) {
      _showSnack(userMessage(e, action: 'replace the photo', stack: st),
          error: true);
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _removeImage(int index) {
    if (_isSubmitting) return;
    final slot = _images[index];
    // An upload from a failed attempt that is now discarded.
    if (slot.local != null && slot.uploadedUrl != null) {
      _firestore.deleteOwnProductImage(slot.uploadedUrl!);
    }
    setState(() => _images.removeAt(index));
  }

  /// Uploads every picked photo that isn't uploaded yet. Already-uploaded
  /// photos are reused, so a retry after a failure doesn't re-upload them.
  /// Returns the final URL list in display order.
  Future<List<String>> _uploadPendingImages() async {
    for (final slot in _images) {
      if (slot.url != null || slot.uploadedUrl != null) continue;
      setState(() {
        slot.failed = false;
        slot.progress = 0;
      });
      try {
        final stored = await _firestore.uploadProductImage(
          slot.local!,
          onProgress: (p) {
            if (mounted) setState(() => slot.progress = p);
          },
        );
        if (mounted) setState(() => slot.uploadedUrl = stored.url);
      } catch (_) {
        if (mounted) setState(() => slot.failed = true);
        rethrow;
      }
    }
    return [for (final slot in _images) slot.url ?? slot.uploadedUrl!];
  }

  void _showPresetProducePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.collections_outlined,
                          color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Select Sri Lankan Produce Template',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: DemoCatalogData.presetProduceItems.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final item = DemoCatalogData.presetProduceItems[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 4),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 52,
                            height: 52,
                            child: SafeImage(
                              path: item['imagePath'] ?? '',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        title: Text(
                          item['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${item['category']} · LKR ${item['defaultPrice']} / ${item['unit']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.add_circle_outline,
                            color: AppColors.primary),
                        onTap: () {
                          final name = item['name'] ?? '';
                          final cat = item['category'] ?? 'Vegetables';
                          final unitVal = item['unit'] ?? 'kg';
                          final price = item['defaultPrice'] ?? '100';
                          final img = item['imagePath'] ?? '';
                          setState(() {
                            _nameController.text = name;
                            _category = cat;
                            _unit = unitVal;
                            _priceController.text = price;
                            if (_quantityController.text.isEmpty) {
                              _quantityController.text = '100';
                            }
                            _descriptionController.text =
                                'Fresh premium quality $name grown locally with care.';
                            if (img.isNotEmpty &&
                                !_images.any((s) => s.url == img)) {
                              _images.add(_ImageSlot.remote(img));
                            }
                          });
                          Navigator.pop(ctx);
                          _showSnack('Loaded preset for $name');
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    final state = context.read<FarmoraState>();
    final name = _nameController.text.trim();
    final quantityVal = int.tryParse(_quantityController.text.trim()) ?? 0;
    final priceVal = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final description = _descriptionController.text.trim();

    if (quantityVal < 0 || priceVal < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.farmerAddProductInvalidQtyPrice)),
      );
      return;
    }

    final isEdit = widget.existingProduct != null;
    final productId = isEdit ? widget.existingProduct!.id : '';
    final productStatus = isEdit ? widget.existingProduct!.status : 'Active';
    final location = _district;
    final signedIn = state.currentUserId.isNotEmpty;
    final farmerId = signedIn ? state.currentUserId : 'farmer_demo_1';

    setState(() => _isSubmitting = true);
    // 1. Upload photos first so Firestore never stores a broken reference.
    List<String> media;
    try {
      media = signedIn
          ? await _uploadPendingImages()
          : [for (final slot in _images) if (slot.url != null) slot.url!];
    } catch (e, st) {
      debugPrint('Photo upload error, using local/preset urls: $e');
      media = [for (final slot in _images) if (slot.url != null) slot.url!];
    }
    if (!mounted) return;

    final newProduct = Product(
      id: productId,
      name: name,
      category: _category,
      location: location,
      quantity: '$quantityVal $_unit available',
      unit: _unit,
      price: 'LKR ${priceVal.toStringAsFixed(2)} / $_unit',
      pricePerUnit: priceVal,
      priceMinor: (priceVal * 100).round(),
      quantityAvailable: quantityVal,
      emoji: _category == 'Fruits'
          ? '🍌'
          : _category == 'Spices'
              ? '🌿'
              : _category == 'Grains'
                  ? '🌾'
                  : '🥬',
      color: const Color(0xFFE8F5E9),
      imagePath: media.isNotEmpty ? media.first : null,
      status: productStatus,
      isOrganic: _isOrganic,
      description: description,
      availabilityDate: _availabilityDate,
      farmerId: farmerId,
      images: media,
      media: media,
      imageUrls: media,
    );

    // 2. Persist the product into catalog and backend.
    try {
      if (isEdit) {
        await state.updateProduct(newProduct);
        // Replaced/removed photos are no longer referenced anywhere.
        for (final url in _originalUrls.difference(media.toSet())) {
          _firestore.deleteOwnProductImage(url);
        }
      } else {
        final newId = await state.addProduct(newProduct);
        if (!mounted) return;
        final uploadVideo = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(ctx.l10n.addHarvestVideo),
            content: Text(ctx.l10n.farmerAddProductVideoPrompt),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(ctx.l10n.skip),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(ctx.l10n.upload),
              ),
            ],
          ),
        );
        if (uploadVideo == true && mounted) {
          final file = await _picker.pickVideo(
            source: ImageSource.gallery,
            maxDuration: const Duration(minutes: 3),
          );
          if (file != null) {
            // The product is already published; a video failure must not be
            // reported as a publish failure.
            try {
              final bytes = await file.readAsBytes();
              final uploaded = await state.uploadHarvestVideo(
                productId: newId,
                bytes: bytes,
                fileName: file.name,
              );
              if (uploaded == null && mounted) {
                _showSnack(context.l10n.farmerProductsVideoUploadFailed,
                    error: true);
              }
            } catch (e, st) {
              if (mounted) {
                _showSnack(
                  context.l10n.farmerProductsVideoUploadFailedReason(
                      userMessage(e,
                          action: 'upload the harvest video', stack: st)),
                  error: true,
                );
              }
            }
          }
        }
      }
      _saved = true;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          content: Text(isEdit
              ? context.l10n.farmerAddProductUpdated(name)
              : context.l10n.farmerAddProductPublished(name)),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (e, st) {
      if (!mounted) return;
      _showSnack(
        userMessage(e,
            action: isEdit ? 'update this product' : 'publish this product',
            stack: st),
        error: true,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.surface,
      // Stitch: fixed top-0 h-16 px-margin-mobile flex items-center gap-md
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.90),
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.existingProduct != null
              ? l.farmerAddProductEditTitle
              : l.addProduct,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Basic Details — Stitch: bg-surface-container-low rounded-xl p-md shadow-sm
                  _buildSectionCard(
                    title: l.farmerAddProductBasicDetails,
                    children: [
                      _buildFieldLabel(l.farmerAddProductNameLabel),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        validator: (v) => (v == null || v.trim().isEmpty) ? l.farmerAddProductNameRequired : null,
                        decoration: _inputDecoration(l.farmerAddProductNameHint),
                      ),
                      const SizedBox(height: 18),
                      _buildFieldLabel(l.category),
                      const SizedBox(height: 6),
                      _buildDropdown(
                        value: _category,
                        items: const [
                          'Vegetables',
                          'Fruits',
                          'Spices',
                          'Grains',
                          'Herbs',
                        ],
                        labelOf: (v) => farmerCategoryLabel(v, l),
                        onChanged: (val) {
                          if (val != null) setState(() => _category = val);
                        },
                      ),
                      const SizedBox(height: 18),
                      _buildFieldLabel(l.farmerAddProductDistrict),
                      const SizedBox(height: 6),
                      _buildDropdown(
                        value: _district,
                        items: _districts,
                        labelOf: (v) => districtLabel(v, l),
                        onChanged: (val) {
                          if (val != null) setState(() => _district = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      // Own Material so the tile's ink isn't hidden by the
                      // decorated section card.
                      Material(
                        color: Colors.transparent,
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l.organicCertified),
                          value: _isOrganic,
                          onChanged: (v) => setState(() => _isOrganic = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. Inventory & Pricing
                  _buildSectionCard(
                    title: l.farmerAddProductInventory,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel(l.quantity),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _quantityController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? l.farmerAddProductQtyRequired : null,
                                  decoration: _inputDecoration('0.00'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel(l.unit),
                                const SizedBox(height: 6),
                                _buildDropdown(
                                  value: _unit,
                                  items: const ['kg', 'lbs', 'pcs', 'box', 'bunches'],
                                  labelOf: (v) => farmerUnitLabel(v, l),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _unit = val);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _buildFieldLabel(l.farmerPricePerUnit),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => (v == null || v.trim().isEmpty) ? l.farmerAddProductPriceRequired : null,
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.onSurfaceVariant
                                .withValues(alpha: 0.50),
                          ),
                          // LKR prefix for Sri Lankan pricing
                          prefixText: 'LKR ',
                          prefixStyle: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            color: AppColors.onSurfaceVariant,
                          ),
                          filled: true,
                          fillColor: AppColors.surfaceContainerLowest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.outlineVariant),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.outlineVariant),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildFieldLabel(l.farmerAddProductAvailabilityDate),
                      const SizedBox(height: 6),
                      // Stitch: date input with calendar icon
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.outlineVariant),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _availabilityDate != null
                                      ? AppFormat.date(_availabilityDate!)
                                      : l.farmerAddProductSelectDate,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ),
                              const Icon(Icons.calendar_today_outlined,
                                  color: AppColors.onSurfaceVariant, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. Description
                  _buildSectionCard(
                    title: l.description,
                    children: [
                      // Screen reader label
                      Offstage(child: Text(l.productDescription)),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: _inputDecoration(
                          l.farmerAddProductDescriptionHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 4. Product Images — Stitch: grid grid-cols-3 gap-sm, aspect-square cells
                  _buildSectionCard(
                    title: l.farmerAddProductImages,
                    subtitle: l.farmerAddProductImagesHint(_maxImages),
                    children: [
                      OutlinedButton.icon(
                        onPressed: _isSubmitting || _isPicking
                            ? null
                            : _showPresetProducePicker,
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('Choose from Produce & Photo Presets'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          // aspect-square = 1:1
                          childAspectRatio: 1.0,
                        ),
                        itemCount: _images.length < _maxImages
                            ? _images.length + 1
                            : _images.length,
                        itemBuilder: (context, index) {
                          if (index == _images.length) return _buildAddTile();
                          return _buildImageTile(index);
                        },
                      ),
                      if (_images.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          l.farmerAddProductImagesTip,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Sticky bottom Publish button
          // Stitch: fixed bottom-0 p-margin-mobile bg-surface/90 backdrop-blur
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.92),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting || _isPicking ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    // Stitch: bg-primary text-on-primary rounded-xl h-touch-target
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.publish_rounded, size: 20),
                  label: Text(
                    _isSubmitting
                        ? (_images.any((i) =>
                                i.local != null && i.uploadedUrl == null)
                            ? l.farmerAddProductUploadingPhotos
                            : l.farmerSaving)
                        : (widget.existingProduct != null
                            ? l.saveChanges
                            : l.farmerAddProductPublish),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Stitch: bg-surface border-2 border-dashed border-primary/50
  Widget _buildAddTile() {
    final disabled = _isPicking || _isSubmitting;
    return InkWell(
      onTap: disabled ? null : _pickImages,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: disabled ? 0.2 : 0.5),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _isPicking
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_photo_alternate_outlined,
                    color: AppColors.primary, size: 28),
            const SizedBox(height: 4),
            Text(
              context.l10n.farmerAddProductAddPhoto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Stitch: relative aspect-square rounded-xl overflow-hidden
  Widget _buildImageTile(int index) {
    final slot = _images[index];
    final uploading =
        _isSubmitting && slot.local != null && slot.uploadedUrl == null;
    final Widget preview = slot.local != null
        ? Image.memory(slot.local!.bytes, fit: BoxFit.cover, gaplessPlayback: true)
        : SafeImage(
            path: slot.url!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.surfaceContainer,
              child: const Icon(Icons.broken_image_outlined,
                  color: AppColors.onSurfaceVariant),
            ),
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Semantics(
            button: true,
            label: context.l10n.farmerAddProductPhotoSemantics(index + 1),
            child: GestureDetector(
              onTap: () => _replaceImage(index),
              child: preview,
            ),
          ),
          if (uploading)
            Container(
              color: Colors.black.withValues(alpha: 0.45),
              alignment: Alignment.center,
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  value: slot.progress > 0 ? slot.progress : null,
                  strokeWidth: 3,
                  color: Colors.white,
                  backgroundColor: Colors.white24,
                ),
              ),
            ),
          if (slot.failed && !uploading)
            Container(
              color: AppColors.error.withValues(alpha: 0.55),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  Text(context.l10n.statusFailed,
                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          if (index == 0)
            Positioned(
              left: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(context.l10n.farmerAddProductCover,
                    style: const TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ),
          // Stitch: close button top-1 right-1 bg-surface/80 rounded-full
          if (!_isSubmitting)
            Positioned(
              top: 4,
              right: 4,
              child: Semantics(
                button: true,
                label: context.l10n.farmerAddProductRemovePhoto(index + 1),
                child: InkWell(
                  onTap: () => _removeImage(index),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.close,
                        size: 16, color: AppColors.error),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Stitch: bg-surface-container-low rounded-xl p-md shadow-sm mb-lg
  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stitch: h2 font-headline-md text-headline-md text-on-surface mb-md
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // Stitch: label block font-label-md text-label-md text-on-surface-variant mb-xs
  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }

  // Stitch: input h-[56px] px-md rounded-lg bg-surface border border-outline-variant focus:border-primary
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: 'Inter',
        color: AppColors.onSurfaceVariant.withValues(alpha: 0.50),
      ),
      filled: true,
      fillColor: AppColors.surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }

  // Stitch: select appearance-none h-[56px] px-md rounded-lg bg-surface border
  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String Function(String value)? labelOf,
  }) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.expand_more,
              color: AppColors.onSurfaceVariant, size: 22),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                labelOf?.call(item) ?? item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// A product photo: either already stored ([url]) or picked on this device
/// ([local]) and, once uploaded, available at [uploadedUrl].
class _ImageSlot {
  _ImageSlot.remote(String this.url) : local = null;
  _ImageSlot.local(PickedImage this.local) : url = null;

  final String? url;
  final PickedImage? local;
  String? uploadedUrl;
  double progress = 0;
  bool failed = false;
}
