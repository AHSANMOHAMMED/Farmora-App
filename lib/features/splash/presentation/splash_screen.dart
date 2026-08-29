import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/farmora_logo.dart';
import '../../onboarding/presentation/onboarding_screen.dart';

/// Clean and modern splash screen for the Farmora mobile application.
///
/// Features a soft green gradient, centered Leaf + Wheat emblem,
/// bold brand title, three-pillar agricultural tagline, and a subtle
/// modern loading indicator at the bottom.
class SplashScreen extends StatefulWidget {
  /// The duration to display the splash screen before auto-navigating.
  /// Set to [Duration.zero] in tests to skip timer delays.
  final Duration duration;

  /// Optional callback invoked when initialization/animation is complete.
  final VoidCallback? onInitializationComplete;

  /// Whether to automatically navigate to [OnboardingScreen] upon completion.
  final bool autoNavigate;

  /// Whether to use the raster image asset instead of vector custom paint.
  final bool useAssetImage;

  const SplashScreen({
    super.key,
    this.duration = const Duration(milliseconds: 2600),
    this.onInitializationComplete,
    this.autoNavigate = true,
    this.useAssetImage = false,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _taglineFadeAnimation;
  late final Animation<double> _loadingFadeAnimation;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // Smooth staggered curves
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _taglineFadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.4, 0.9, curve: Curves.easeIn),
    );

    _loadingFadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
    );

    _animController.forward();

    // Start auto-navigation timer if duration is provided
    if (widget.duration > Duration.zero) {
      _timer = Timer(widget.duration, _handleCompletion);
    }
  }

  void _handleCompletion() {
    if (!mounted) return;

    if (widget.onInitializationComplete != null) {
      widget.onInitializationComplete!();
    } else if (widget.autoNavigate) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const OnboardingScreen(),
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
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: GestureDetector(
        onTap: () {
          // Allow instant skip on tap
          _timer?.cancel();
          _handleCompletion();
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.splashGradientStart,
                AppColors.splashGradientMid,
                AppColors.splashGradientEnd,
              ],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Ambient soft organic backdrop glow circles
              Positioned(
                top: -size.width * 0.25,
                right: -size.width * 0.2,
                child: _buildAmbientGlow(
                  size.width * 0.85,
                  AppColors.primary.withValues(alpha: 0.08),
                ),
              ),
              Positioned(
                bottom: -size.width * 0.3,
                left: -size.width * 0.2,
                child: _buildAmbientGlow(
                  size.width * 0.9,
                  AppColors.accentWheat.withValues(alpha: 0.06),
                ),
              ),

              // Main Centered Content & Bottom Loading
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    children: [
                      const Spacer(flex: 3),

                      // Centered Logo + Brand Identity
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 1. Logo: Leaf + Wheat Icon in soft container
                              FarmoraLogo(
                                size: 120,
                                showBadge: true,
                                useAssetImage: widget.useAssetImage,
                              ),
                              const SizedBox(height: 24),

                              // 2. App Name: Farmora in bold modern typography
                              SlideTransition(
                                position: _slideAnimation,
                                child: Column(
                                  children: [
                                    const Text(
                                      'Farmora',
                                      style: TextStyle(
                                        fontSize: 42,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.8,
                                        color: AppColors.forestGreen,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // 3. Tagline: Connecting Farmers, Buyers & Transport
                                    FadeTransition(
                                      opacity: _taglineFadeAnimation,
                                      child: Column(
                                        children: [
                                          const Text(
                                            'Connecting Farmers, Buyers & Transport',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.15,
                                              color: AppColors.textSecondary,
                                              height: 1.35,
                                            ),
                                          ),
                                          const SizedBox(height: 16),

                                          // Minimal agricultural pillar chips
                                          _buildPillRow(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(flex: 4),

                      // Bottom: Subtle Loading Indicator & Status
                      FadeTransition(
                        opacity: _loadingFadeAnimation,
                        child: _buildBottomLoader(),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ambient decorative glow orb for organic depth
  Widget _buildAmbientGlow(double diameter, Color color) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }

  /// Minimal agricultural category pill indicators
  Widget _buildPillRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPill(icon: Icons.eco_outlined, label: 'Farmers'),
        const SizedBox(width: 8),
        _buildDotSeparator(),
        const SizedBox(width: 8),
        _buildPill(icon: Icons.storefront_outlined, label: 'Buyers'),
        const SizedBox(width: 8),
        _buildDotSeparator(),
        const SizedBox(width: 8),
        _buildPill(icon: Icons.local_shipping_outlined, label: 'Transport'),
      ],
    );
  }

  Widget _buildPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.forestGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDotSeparator() {
    return Container(
      width: 3.5,
      height: 3.5,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.35),
        shape: BoxShape.circle,
      ),
    );
  }

  /// Modern, subtle loading bar and version status
  Widget _buildBottomLoader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Subtle progress indicator
        SizedBox(
          width: 140,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 4,
              child: LinearProgressIndicator(
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Subtle loading text & version
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Connecting agricultural network…',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
