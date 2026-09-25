import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/safe_image.dart';
import '../../../models/product.dart';
import '../../../providers/farmora_state.dart';
import '../../../services/firebase_service.dart';

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
  final _firestore = FirestoreService();

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

  final List<String> _selectedImages = [];
  bool _isSubmitting = false;
  bool _isPicking = false;

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
      if (existingMedia.isNotEmpty) {
        _selectedImages.addAll(existingMedia);
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

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 5 || _isPicking) return;
    setState(() => _isPicking = true);
    try {
      final remaining = 5 - _selectedImages.length;
      final files = await _picker.pickMultiImage(
        imageQuality: 75,
        maxWidth: 1600,
      );
      if (files.isEmpty) return;
      final urls = <String>[];
      var failedUploads = 0;
      for (final file in files.take(remaining)) {
        final bytes = await file.readAsBytes();
        final contentType = file.mimeType ?? 'image/jpeg';
        try {
          final url = await _firestore.uploadProductImage(
            bytes: bytes,
            fileName: file.name,
            contentType: contentType,
          );
          urls.add(url);
        } catch (_) {
          // Base64 image data cannot be used reliably by the cloud workflow
          // and can exceed Firestore's document limit. Keep only uploaded URLs.
          failedUploads++;
        }
      }
      if (!mounted) return;
      setState(() => _selectedImages.addAll(urls));
      if (failedUploads > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(urls.isEmpty
                ? 'Could not upload the selected images. Check your connection and try again.'
                : '$failedUploads image(s) could not be uploaded. The remaining images were added.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image selection issue: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    final state = context.read<FarmoraState>();
    if (state.currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to publish products.')),
      );
      return;
    }
    final name = _nameController.text.trim();
    final quantityVal = int.tryParse(_quantityController.text.trim()) ?? 0;
    final priceVal = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final description = _descriptionController.text.trim();

    if (quantityVal < 0 || priceVal < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid quantity and price.')),
      );
      return;
    }

    final isEdit = widget.existingProduct != null;
    final productId = isEdit ? widget.existingProduct!.id : '';
    final productStatus = isEdit ? widget.existingProduct!.status : 'Active';
    final media = List<String>.from(_selectedImages);

    final location = _district;

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
      images: media,
      media: media,
      imageUrls: media,
    );

    setState(() => _isSubmitting = true);
    try {
      if (isEdit) {
        await state.updateProduct(newProduct);
      } else {
        final newId = await _firestore.createSecureProduct(newProduct);
        if (!mounted) return;
        final uploadVideo = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Add harvest video?'),
            content: const Text(
              'Optional: upload a short harvest video (MP4, max 100 MB). '
              'It is auto-deleted after delivery.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Skip'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Upload'),
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
            final bytes = await file.readAsBytes();
            await state.uploadHarvestVideo(
              productId: newId,
              bytes: bytes,
              fileName: file.name,
            );
          }
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          content: Text(isEdit
              ? 'Updated $name successfully!'
              : 'Published $name successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('verification')
          ? 'Account verification is required before publishing products.'
          : 'Failed to save product: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          widget.existingProduct != null ? 'Edit Product' : 'Add Product',
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
                    title: 'Basic Details',
                    children: [
                      _buildFieldLabel('Product Name'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter a product name'
                            : null,
                        decoration:
                            _inputDecoration('e.g. Nuwara Eliya Carrots'),
                      ),
                      const SizedBox(height: 18),
                      _buildFieldLabel('Category'),
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
                        onChanged: (val) {
                          if (val != null) setState(() => _category = val);
                        },
                      ),
                      const SizedBox(height: 18),
                      _buildFieldLabel('Farm District / Location'),
                      const SizedBox(height: 6),
                      _buildDropdown(
                        value: _district,
                        items: _districts,
                        onChanged: (val) {
                          if (val != null) setState(() => _district = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Organic certified'),
                        value: _isOrganic,
                        onChanged: (v) => setState(() => _isOrganic = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. Inventory & Pricing
                  _buildSectionCard(
                    title: 'Inventory & Pricing',
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Quantity'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _quantityController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Enter qty'
                                          : null,
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
                                _buildFieldLabel('Unit'),
                                const SizedBox(height: 6),
                                _buildDropdown(
                                  value: _unit,
                                  items: const [
                                    'kg',
                                    'lbs',
                                    'pcs',
                                    'box',
                                    'bunches'
                                  ],
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
                      _buildFieldLabel('Price per unit'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter price'
                            : null,
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
                      _buildFieldLabel('Availability Date'),
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
                              Text(
                                _availabilityDate != null
                                    ? DateFormat('yyyy-MM-dd')
                                        .format(_availabilityDate!)
                                    : 'Select date',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  color: AppColors.onSurface,
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
                    title: 'Description',
                    children: [
                      // Screen reader label
                      const Offstage(child: Text('Product Description')),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: _inputDecoration(
                          'Describe the quality, origin, and any certifications...',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 4. Product Images — Stitch: grid grid-cols-3 gap-sm, aspect-square cells
                  _buildSectionCard(
                    title: 'Product Images',
                    subtitle: 'Upload up to 5 clear photos of your product.',
                    children: [
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
                        itemCount: _selectedImages.length < 5
                            ? _selectedImages.length + 1
                            : _selectedImages.length,
                        itemBuilder: (context, index) {
                          // Add tile
                          if (index == _selectedImages.length &&
                              _selectedImages.length < 5) {
                            return InkWell(
                              onTap: _isPicking ? null : _pickImages,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                decoration: BoxDecoration(
                                  // Stitch: bg-surface border-2 border-dashed border-primary/50
                                  color: AppColors.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.50),
                                    width: 2,
                                    // Dashed border via decoration
                                  ),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      color: AppColors.primary,
                                      size: 28,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Add',
                                      style: TextStyle(
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

                          // Image preview tile — Stitch: relative aspect-square rounded-xl overflow-hidden
                          final imgPath = _selectedImages[index];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                SafeImage(
                                  path: imgPath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: AppColors.surfaceContainer,
                                    child: const Icon(Icons.image_outlined,
                                        color: AppColors.onSurfaceVariant),
                                  ),
                                ),
                                // Stitch: close button top-1 right-1 w-8 h-8 bg-surface/80 rounded-full
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: InkWell(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.85),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.12),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
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
                  onPressed: _isSubmitting ? null : _submit,
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
                        ? 'Saving...'
                        : (widget.existingProduct != null
                            ? 'Save Changes'
                            : 'Publish Product'),
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
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
