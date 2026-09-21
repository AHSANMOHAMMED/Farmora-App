import 'package:flutter/material.dart';
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
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  String _selectedUnit = 'kg';
  DateTime? _availabilityDate;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
          style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.onSurface),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildProfileAvatar(),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                const Text(
                  'List New Harvest',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Share your latest crop with the marketplace.',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 24),

                // ── Product Name ──
                _buildFieldCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Product Name', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Organic Roma Tomatoes',
                          hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 15, color: Color(0xFFB0B0B0)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 15),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Category & Available From ──
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildFieldCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Category', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedCategory,
                              hint: const Text('Select...', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFFB0B0B0))),
                              decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                              items: const [
                                DropdownMenuItem(value: 'Vegetables', child: Text('Vegetables')),
                                DropdownMenuItem(value: 'Fruits', child: Text('Fruits')),
                                DropdownMenuItem(value: 'Grains', child: Text('Grains')),
                                DropdownMenuItem(value: 'Herbs', child: Text('Herbs')),
                                DropdownMenuItem(value: 'Dairy', child: Text('Dairy')),
                              ],
                              onChanged: (val) => setState(() => _selectedCategory = val),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: _buildFieldCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Available From', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant)),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) setState(() => _availabilityDate = date);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0)))),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _availabilityDate != null
                                          ? '${_availabilityDate!.month}/${_availabilityDate!.day}/${_availabilityDate!.year}'
                                          : 'mm/dd/y',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        color: _availabilityDate != null ? AppColors.onSurface : const Color(0xFFB0B0B0),
                                      ),
                                    ),
                                    const Icon(Icons.calendar_today, size: 18, color: AppColors.onSurfaceVariant),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Quantity, Unit, Price ──
                _buildFieldCard(
                  child: Row(
                    children: [
                      // Quantity
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Quantity', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: '0',
                                hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 15, color: Color(0xFFB0B0B0)),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 40, color: const Color(0xFFE0E0E0)),
                      // Unit
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Unit', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedUnit,
                                decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                                items: const [
                                  DropdownMenuItem(value: 'kg', child: Text('kg')),
                                  DropdownMenuItem(value: 'lb', child: Text('lb')),
                                  DropdownMenuItem(value: 'box', child: Text('box')),
                                  DropdownMenuItem(value: 'unit', child: Text('unit')),
                                ],
                                onChanged: (val) => setState(() => _selectedUnit = val ?? 'kg'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(width: 1, height: 40, color: const Color(0xFFE0E0E0)),
                      // Price
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Price / Unit', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text('\$', style: TextStyle(fontFamily: 'Inter', fontSize: 15, color: AppColors.onSurfaceVariant)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: TextField(
                                      controller: _priceController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        hintText: '0.00',
                                        hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 15, color: Color(0xFFB0B0B0)),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      style: const TextStyle(fontFamily: 'Inter', fontSize: 15),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Product Photos ──
                _buildFieldCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Product Photos', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Add Photo button
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, size: 24, color: AppColors.onSurfaceVariant),
                                SizedBox(height: 4),
                                Text('Add Photo', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Placeholder for added photos
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5E6D3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(Icons.eco, size: 32, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Upload up to 5 photos. First image will be the cover.',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Description ──
                _buildFieldCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Description (Optional)', style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Tell buyers about your product, farming practices, or special qualities...',
                          hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFFB0B0B0)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Publish Button ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.95),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4)),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _publishProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.publish, size: 20),
                label: const Text(
                  'Publish Product',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
      child: const Icon(Icons.person, color: Colors.white, size: 22),
    );
  }

  Widget _buildFieldCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }

  void _publishProduct() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a product name'), backgroundColor: AppColors.error),
      );
      return;
    }

    final product = Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      category: _selectedCategory ?? 'Vegetables',
      location: 'Farm Location',
      quantity: _quantityController.text.isNotEmpty ? _quantityController.text : '0',
      unit: _selectedUnit,
      price: 'LKR ${_priceController.text.isNotEmpty ? _priceController.text : '0.00'}/$_selectedUnit',
      pricePerUnit: double.tryParse(_priceController.text) ?? 0.0,
      description: _descriptionController.text,
      availabilityDate: _availabilityDate,
      status: 'Active',
      isOrganic: true,
    );

    context.read<FarmoraState>().addProduct(product);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product published successfully!'), backgroundColor: AppColors.primary),
    );
    Navigator.of(context).pop();
  }
}
