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
  DateTime? _availabilityDate = DateTime.now().add(const Duration(days: 1));

  final List<String> _selectedImages = [
    'assets/images/roma_tomatoes_1.png',
    'assets/images/roma_tomatoes_2.png',
  ];

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
      quantity: '$quantityVal $_unit available',
      unit: _unit,
      price: '\$${priceVal.toStringAsFixed(2)} / $_unit',
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
      // Stitch: fixed top-0 h-16 px-margin-mobile flex items-center gap-md
      appBar: AppBar(
        backgroundColor: AppColors.surface.withOpacity(0.90),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.04),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Add Product',
          style: TextStyle(
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
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a product name' : null,
                        decoration: _inputDecoration('e.g. Organic Roma Tomatoes'),
                      ),
                      const SizedBox(height: 18),
                      _buildFieldLabel('Category'),
                      const SizedBox(height: 6),
                      _buildDropdown(
                        value: _category,
                        items: const ['Vegetables', 'Fruits', 'Grains', 'Dairy', 'Herbs'],
                        onChanged: (val) {
                          if (val != null) setState(() => _category = val);
                        },
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
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter qty' : null,
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
                      const SizedBox(height: 18),
                      _buildFieldLabel('Price per unit'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter price' : null,
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.onSurfaceVariant.withOpacity(0.50),
                          ),
                          // Stitch: $ prefix
                          prefixText: '\$  ',
                          prefixStyle: const TextStyle(
                            fontFamily: 'Inter',
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
                                    ? DateFormat('yyyy-MM-dd').format(_availabilityDate!)
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
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                          if (index == _selectedImages.length && _selectedImages.length < 5) {
                            return InkWell(
                              onTap: _addImageMock,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                decoration: BoxDecoration(
                                  // Stitch: bg-surface border-2 border-dashed border-primary/50
                                  color: AppColors.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.50),
                                    width: 2,
                                    // Dashed border via decoration
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.add_photo_alternate_outlined,
                                      color: AppColors.primary,
                                      size: 28,
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
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
                                Image.asset(
                                  imgPath,
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
                                        color: Colors.white.withOpacity(0.85),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.12),
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
                color: AppColors.surface.withOpacity(0.92),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    // Stitch: bg-primary text-on-primary rounded-xl h-touch-target
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.publish_rounded, size: 20),
                  label: const Text(
                    'Publish Product',
                    style: TextStyle(
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
            color: Colors.black.withOpacity(0.02),
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
        color: AppColors.onSurfaceVariant.withOpacity(0.50),
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
