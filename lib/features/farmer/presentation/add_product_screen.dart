import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/product.dart';
import '../../../providers/farmora_state.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _category = 'Vegetables';
  String _unit = 'kg';
  DateTime? _availabilityDate;
  final List<String> _selectedImages = [];

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
      initialDate: _availabilityDate ?? DateTime.now().add(const Duration(days: 1)),
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

  void _addImageMock() {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 images allowed.')),
      );
      return;
    }
    setState(() {
      _selectedImages.add('assets/images/heirloom_tomatoes.png');
    });
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final quantityVal = _quantityController.text.trim();
    final priceVal = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final description = _descriptionController.text.trim();

    final newProduct = Product(
      id: 'prod-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      category: _category,
      location: 'Local Farm',
      quantity: '$quantityVal $_unit',
      unit: _unit,
      price: 'LKR ${priceVal.toStringAsFixed(2)}/$_unit',
      pricePerUnit: priceVal,
      emoji: _category == 'Fruits' ? '🍎' : '🍅',
      color: const Color(0xFFFFE1DA),
      imagePath: _selectedImages.isNotEmpty ? _selectedImages.first : 'assets/images/heirloom_tomatoes.png',
      status: 'Active',
      isOrganic: true,
      description: description,
      availabilityDate: _availabilityDate,
      images: _selectedImages,
    );

    context.read<FarmoraState>().addProduct(newProduct);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        content: Text('Published $name successfully!'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Add Product',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Photo Upload Area ─────────────────────
                  _buildPhotoUploadArea(),
                  const SizedBox(height: 24),

                  // ── Product Name ─────────────────────────
                  _buildFieldLabel('Product Name'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a product name' : null,
                    decoration: _inputDecoration('e.g. Organic Roma Tomatoes'),
                  ),
                  const SizedBox(height: 20),

                  // ── Category ─────────────────────────────
                  _buildFieldLabel('Category'),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    value: _category,
                    items: const ['Vegetables', 'Fruits', 'Grains', 'Dairy', 'Herbs'],
                    onChanged: (val) {
                      if (val != null) setState(() => _category = val);
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── Quantity + Unit ──────────────────────
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Total Quantity'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _quantityController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter qty' : null,
                              decoration: _inputDecoration('Enter quantity'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Unit Type'),
                            const SizedBox(height: 8),
                            _buildDropdown(
                              value: _unit,
                              items: const ['kg', 'lbs', 'pcs', 'box', 'bunches'],
                              onChanged: (val) {
                                if (val != null) setState(() => _unit = val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Price per Unit ───────────────────────
                  _buildFieldLabel('Price per Unit'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter price' : null,
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.50),
                      ),
                      prefixText: 'LKR ',
                      prefixStyle: const TextStyle(
                        fontSize: 15,
                        color: AppColors.onSurfaceVariant,
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Availability Date ────────────────────
                  _buildFieldLabel('Availability Date'),
                  const SizedBox(height: 8),
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
                                ? DateFormat('MM/dd/yyyy').format(_availabilityDate!)
                                : 'mm/dd/yyyy',
                            style: TextStyle(
                              fontSize: 15,
                              color: _availabilityDate != null
                                  ? AppColors.onSurface
                                  : AppColors.onSurfaceVariant.withValues(alpha: 0.50),
                            ),
                          ),
                          const Icon(Icons.calendar_today_outlined,
                              color: AppColors.onSurfaceVariant, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Description ──────────────────────────
                  _buildFieldLabel('Description'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: _inputDecoration(
                      'Provide details about the harvest quality, farming methods used, etc.',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Photo preview thumbnails ─────────────
                  if (_selectedImages.isNotEmpty) ...[
                    _buildFieldLabel('Selected Photos'),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset(
                                  _selectedImages[index],
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 80,
                                    height: 80,
                                    color: AppColors.surfaceContainer,
                                    child: const Icon(Icons.image_outlined,
                                        color: AppColors.onSurfaceVariant),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 3,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.close, size: 14, color: AppColors.error),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Sticky Publish Button ───────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
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
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.publish_rounded, size: 20),
                  label: const Text(
                    'Publish Product',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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

  // ── Photo Upload Area (dashed border) ──────────────────────
  Widget _buildPhotoUploadArea() {
    return GestureDetector(
      onTap: _addImageMock,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8E9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.30),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_a_photo_outlined,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Add Photos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to upload harvest images',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
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
          icon: const Icon(Icons.expand_more, color: AppColors.onSurfaceVariant, size: 22),
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
