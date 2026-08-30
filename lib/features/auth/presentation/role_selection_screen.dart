import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/farmora_logo.dart';
import '../../../models/user_role.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// Role card configuration model.
class _RoleOption {
  final Role role;
  final String title;
  final String description;
  final IconData icon;

  const _RoleOption({
    required this.role,
    required this.title,
    required this.description,
    required this.icon,
  });
}

/// Clean, modern, and simple role selection screen for Farmora.
///
/// Features large selectable cards for Farmer, Buyer, and Transport Provider,
/// and a Continue button that remains disabled until a role is selected.
class RoleSelectionScreen extends StatefulWidget {
  final Role? initialRole;
  final ValueChanged<Role>? onRoleSelected;

  const RoleSelectionScreen({
    super.key,
    this.initialRole,
    this.onRoleSelected,
  });

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  Role? _selectedRole;

  static const List<_RoleOption> _roleOptions = [
    // 1. Farmer
    _RoleOption(
      role: Role.farmer,
      title: 'Farmer',
      description: 'I want to sell my products',
      icon: Icons.agriculture_rounded,
    ),
    // 2. Buyer
    _RoleOption(
      role: Role.buyer,
      title: 'Buyer',
      description: 'I want to buy products',
      icon: Icons.shopping_basket_rounded,
    ),
    // 3. Transport Provider
    _RoleOption(
      role: Role.transporter,
      title: 'Transport Provider',
      description: 'I want to deliver products',
      icon: Icons.local_shipping_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
  }

  void _handleContinue() {
    if (_selectedRole == null) return;

    if (widget.onRoleSelected != null) {
      widget.onRoleSelected!(_selectedRole!);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => RegisterScreen(selectedRole: _selectedRole!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = _selectedRole != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Brand Header
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const FarmoraLogo(
                        size: 26,
                        showBadge: false,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Farmora',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: AppColors.forestGreen,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Title: "Join Farmora as"
              const Text(
                'Join Farmora as',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.forestGreen,
                  letterSpacing: -0.6,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Welcome to Farmora. Choose how you want to participate in the agricultural marketplace.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Three Large Selectable Cards
              ..._roleOptions.map((option) {
                final isCardSelected = _selectedRole == option.role;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildLargeRoleCard(option, isCardSelected),
                );
              }),

              const SizedBox(height: 16),

              // Continue Button (Disabled until a role is selected)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isSelected ? _handleContinue : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: Colors.black12,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.black38,
                    minimumSize: const Size(double.infinity, 56),
                    elevation: isSelected ? 1 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue to Farmora',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                          color: isSelected ? Colors.white : Colors.black38,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: isSelected ? Colors.white : Colors.black38,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Already have an account? Log In Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Log In',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              const Center(
                child: Text(
                  'Demo mode · Instant access',
                  style: TextStyle(color: Colors.black38, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a large, clearly tappable role selection card
  Widget _buildLargeRoleCard(_RoleOption option, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryContainer : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.15),
          width: isSelected ? 2.2 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.14)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: isSelected ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _selectedRole = option.role);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                // 1. Role Icon (Farmer, Basket, Truck)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppColors.primary : AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    option.icon,
                    size: 28,
                    color: isSelected ? Colors.white : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),

                // 2. Role Title & Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? AppColors.forestGreen
                              : AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        option.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected
                              ? AppColors.forestGreen
                              : AppColors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // 3. Selection Radio / Check Indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.black26,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
