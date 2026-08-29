import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/presentation/login_screen.dart';

/// Data model representing an individual onboarding slide.
class OnboardingSlideData {
  final String roleBadge;
  final IconData roleIcon;
  final String title;
  final String description;
  final String imagePath;
  final List<String> highlights;
  final IconData fallbackIcon;

  const OnboardingSlideData({
    required this.roleBadge,
    required this.roleIcon,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.highlights,
    required this.fallbackIcon,
  });
}

/// Clean, modern, and accessible 3-step onboarding screen for Farmora.
///
/// Tailored for rural users and participants with varying digital literacy,
/// featuring large touch targets, high contrast, and role-focused guidance.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const OnboardingScreen({
    super.key,
    this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<OnboardingSlideData> _slides = [
    // Screen 1: Farmer
    OnboardingSlideData(
      roleBadge: 'FOR FARMERS',
      roleIcon: Icons.agriculture_rounded,
      title: 'Sell Your Harvest Directly',
      description:
          'Connect directly with buyers without middlemen. Set your own fair prices and receive fast, guaranteed payouts.',
      imagePath: 'assets/images/onboarding_farmer.png',
      highlights: ['Direct Sales', 'Fair Pricing', 'Fast Payout'],
      fallbackIcon: Icons.eco_rounded,
    ),
    // Screen 2: Buyer
    OnboardingSlideData(
      roleBadge: 'FOR BUYERS',
      roleIcon: Icons.storefront_rounded,
      title: 'Get Fresh Products Easily',
      description:
          'Browse farm-fresh produce straight from local fields. Enjoy trusted quality and transparent wholesale prices.',
      imagePath: 'assets/images/onboarding_buyer.png',
      highlights: ['100% Farm Fresh', 'Direct Sourcing', 'Easy Ordering'],
      fallbackIcon: Icons.shopping_basket_rounded,
    ),
    // Screen 3: Transport
    OnboardingSlideData(
      roleBadge: 'FOR TRANSPORTERS',
      roleIcon: Icons.local_shipping_rounded,
      title: 'Reliable Transport for Every Order',
      description:
          'Find dependable delivery trips along your routes. Transport fresh produce safely and maximize your vehicle earnings.',
      imagePath: 'assets/images/onboarding_transport.png',
      highlights: ['Verified Cargo', 'Guaranteed Trips', 'Extra Income'],
      fallbackIcon: Icons.local_shipping_rounded,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _onPrevious() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _finishOnboarding() {
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Skip button and Branding
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Minimal brand tag
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.eco,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Farmora',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.forestGreen,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  // Skip button (accessible large hit area)
                  if (!isLastPage)
                    TextButton(
                      onPressed: _finishOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),

            // Page View with Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return _buildSlide(slide);
                },
              ),
            ),

            // Bottom Navigation Controls
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Page Indicator Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons (High touch-target accessibility)
                  Row(
                    children: [
                      // Back Button (shown on page 2 and 3)
                      if (_currentPage > 0) ...[
                        OutlinedButton(
                          onPressed: _onPrevious,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(54, 54),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            side: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],

                      // Primary Next / Get Started Button
                      Expanded(
                        child: FilledButton(
                          onPressed: _onNext,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 54),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isLastPage ? 'Get Started' : 'Next',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isLastPage
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a single onboarding slide with large illustration and clear typography
  Widget _buildSlide(OnboardingSlideData slide) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Role Focus Pill Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  slide.roleIcon,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  slide.roleBadge,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: AppColors.forestGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Illustration Container with Soft Card Shadow
          Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: AppColors.primaryLight,
                width: 1.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              slide.imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  _buildImageFallback(slide),
            ),
          ),
          const SizedBox(height: 22),

          // Slide Title
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              height: 1.2,
              color: AppColors.forestGreen,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 12),

          // Friendly, Simple Description
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.45,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // Bullet Highlights Row
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: slide.highlights.map((highlight) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      highlight,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Graceful vector icon fallback in case assets are offline or loading
  Widget _buildImageFallback(OnboardingSlideData slide) {
    return Container(
      color: AppColors.primaryLight,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              slide.fallbackIcon,
              size: 72,
              color: AppColors.primary,
            ),
            const SizedBox(height: 8),
            Text(
              slide.roleBadge,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.forestGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
