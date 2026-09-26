import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/farmora_state.dart';

/// Simple, large-icon farmer profile completion screen.
/// Designed for low-literacy farmers: big tappable options, minimal text input.
class FarmerProfileCompletionScreen extends StatefulWidget {
  const FarmerProfileCompletionScreen({super.key});

  @override
  State<FarmerProfileCompletionScreen> createState() =>
      _FarmerProfileCompletionScreenState();
}

class _FarmerProfileCompletionScreenState
    extends State<FarmerProfileCompletionScreen>
    with TickerProviderStateMixin {
  final _farmNameCtrl = TextEditingController();
  String _selectedDistrict = '';
  String _selectedSize = '';
  final Set<String> _selectedCrops = {};
  bool _saving = false;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  static const List<String> _districts = [
    'Colombo', 'Gampaha', 'Kalutara', 'Kandy', 'Matale', 'Nuwara Eliya',
    'Galle', 'Matara', 'Hambantota', 'Jaffna', 'Kilinochchi', 'Mannar',
    'Vavuniya', 'Mullaitivu', 'Batticaloa', 'Ampara', 'Trincomalee',
    'Kurunegala', 'Puttalam', 'Anuradhapura', 'Polonnaruwa', 'Badulla',
    'Monaragala', 'Ratnapura', 'Kegalle',
  ];

  static const List<_FarmSize> _farmSizes = [
    _FarmSize('🌱', 'Small', '< 1 acre', 'small'),
    _FarmSize('🌿', 'Medium', '1–5 acres', 'medium'),
    _FarmSize('🌳', 'Large', '5–20 acres', 'large'),
    _FarmSize('🏞️', 'Very Large', '> 20 acres', 'xlarge'),
  ];

  static const List<_CropChip> _crops = [
    _CropChip('🍅', 'Tomato'),
    _CropChip('🥕', 'Carrot'),
    _CropChip('🥬', 'Cabbage'),
    _CropChip('🌶️', 'Chilli'),
    _CropChip('🍆', 'Brinjal'),
    _CropChip('🥔', 'Potato'),
    _CropChip('🌾', 'Rice'),
    _CropChip('🫘', 'Beans'),
    _CropChip('🧅', 'Onion'),
    _CropChip('🥒', 'Cucumber'),
    _CropChip('🌽', 'Corn'),
    _CropChip('🍌', 'Banana'),
    _CropChip('🍍', 'Pineapple'),
    _CropChip('🫚', 'Coconut'),
    _CropChip('🍵', 'Tea'),
    _CropChip('☕', 'Coffee'),
    _CropChip('🥭', 'Mango'),
    _CropChip('🍓', 'Strawberry'),
    _CropChip('🐄', 'Dairy'),
    _CropChip('🐔', 'Poultry'),
  ];

  int _step = 0; // 0=farmName, 1=district, 2=size, 3=crops

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _farmNameCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0 && _farmNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your farm name 🌾')));
      return;
    }
    if (_step == 1 && _selectedDistrict.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your district 📍')));
      return;
    }
    if (_step == 2 && _selectedSize.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your farm size 🌿')));
      return;
    }
    if (_step < 3) {
      _fadeCtrl.reset();
      setState(() => _step++);
      _fadeCtrl.forward();
    } else {
      _save();
    }
  }

  Future<void> _save() async {
    if (_selectedCrops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please pick at least one crop 🌱')));
      return;
    }
    setState(() => _saving = true);
    final size = _farmSizes.firstWhere((s) => s.key == _selectedSize);
    try {
      await context.read<FarmoraState>().markProfileComplete(
            farmName: _farmNameCtrl.text.trim(),
            farmSize: size.label,
            district: _selectedDistrict,
            mainCrops: _selectedCrops.toList(),
          );
      // State listener in home_screen will automatically route to farmer dashboard
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF5),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildStep()),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final titles = [
      '🏡 Your Farm Name',
      '📍 Your District',
      '🌿 Farm Size',
      '🌱 What do you grow?',
    ];
    final subtitles = [
      'Give your farm a name',
      'Where is your farm?',
      'How big is your farm?',
      'Select all crops you grow',
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress dots
          Row(
            children: List.generate(4, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 6),
              width: _step == i ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i <= _step ? AppColors.primary : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(4),
              ),
            )),
          ),
          const SizedBox(height: 16),
          Text(titles[_step],
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(subtitles[_step],
              style: const TextStyle(
                  fontSize: 15, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: switch (_step) {
        0 => _buildFarmNameStep(),
        1 => _buildDistrictStep(),
        2 => _buildSizeStep(),
        _ => _buildCropsStep(),
      },
    );
  }

  Widget _buildFarmNameStep() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primaryLight, width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 16)
            ],
          ),
          child: Column(
            children: [
              const Text('🏡', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 20),
              TextField(
                controller: _farmNameCtrl,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'e.g. Green Valley Farm',
                  hintStyle: const TextStyle(
                      color: Colors.black38, fontWeight: FontWeight.normal),
                  filled: true,
                  fillColor: const Color(0xFFF0FDF4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 18),
                ),
                onSubmitted: (_) => _next(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDistrictStep() {
    return Column(
      children: _districts.map((d) {
        final selected = _selectedDistrict == d;
        return GestureDetector(
          onTap: () => setState(() => _selectedDistrict = d),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : AppColors.primaryLight,
                width: 1.5,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 10)
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(Icons.location_on_rounded,
                    color: selected ? Colors.white : AppColors.primary,
                    size: 22),
                const SizedBox(width: 12),
                Text(d,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? Colors.white
                            : AppColors.textPrimary)),
                const Spacer(),
                if (selected)
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 22),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSizeStep() {
    return Column(
      children: [
        const SizedBox(height: 12),
        ..._farmSizes.map((s) {
          final selected = _selectedSize == s.key;
          return GestureDetector(
            onTap: () => setState(() => _selectedSize = s.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.primaryLight,
                  width: selected ? 2.5 : 1.5,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            blurRadius: 12)
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Text(s.emoji, style: const TextStyle(fontSize: 40)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.label,
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textPrimary)),
                        Text(s.range,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  if (selected)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 18),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCropsStep() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _crops.map((c) {
        final selected = _selectedCrops.contains(c.name);
        return GestureDetector(
          onTap: () => setState(() {
            if (selected) {
              _selectedCrops.remove(c.name);
            } else {
              _selectedCrops.add(c.name);
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.primaryLight,
                width: 1.5,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 8)
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(c.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 4),
                Text(c.name,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color:
                            selected ? Colors.white : AppColors.textPrimary)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar() {
    final isLast = _step == 3;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      color: Colors.white,
      child: Row(
        children: [
          if (_step > 0)
            OutlinedButton(
              onPressed: () {
                _fadeCtrl.reset();
                setState(() => _step--);
                _fadeCtrl.forward();
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(100, 56),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Back',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          if (_step > 0) const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _saving ? null : _next,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text(
                      isLast ? '✅ Complete Profile' : 'Next →',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmSize {
  final String emoji;
  final String label;
  final String range;
  final String key;
  const _FarmSize(this.emoji, this.label, this.range, this.key);
}

class _CropChip {
  final String emoji;
  final String name;
  const _CropChip(this.emoji, this.name);
}
