import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// A clean, modern leaf + wheat logo for Farmora.
///
/// Can be rendered as a standalone emblem or within a frosted, elevated circular badge.
class FarmoraLogo extends StatelessWidget {
  final double size;
  final bool showBadge;
  final bool useAssetImage;
  final Color? leafColor;
  final Color? wheatColor;

  const FarmoraLogo({
    super.key,
    this.size = 110,
    this.showBadge = true,
    this.useAssetImage = false,
    this.leafColor,
    this.wheatColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget emblem;

    if (useAssetImage) {
      emblem = Image.asset(
        'assets/images/farmora_logo.png',
        width: size * 0.72,
        height: size * 0.72,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildVectorLogo(),
      );
    } else {
      emblem = _buildVectorLogo();
    }

    if (!showBadge) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(child: emblem),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.92),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 28,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 12,
            spreadRadius: -2,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border.all(
          color: Colors.white,
          width: 2.5,
        ),
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.65,
          height: size * 0.65,
          child: emblem,
        ),
      ),
    );
  }

  Widget _buildVectorLogo() {
    return CustomPaint(
      size: Size(size * 0.65, size * 0.65),
      painter: LeafWheatPainter(
        leafColor: leafColor ?? AppColors.primary,
        leafAccentColor: const Color(0xff2ecc71),
        wheatColor: wheatColor ?? AppColors.accentWheat,
        wheatAccentColor: AppColors.accentWheatLight,
      ),
    );
  }
}

/// Custom vector painter that renders an elegant leaf + wheat motif.
class LeafWheatPainter extends CustomPainter {
  final Color leafColor;
  final Color leafAccentColor;
  final Color wheatColor;
  final Color wheatAccentColor;

  LeafWheatPainter({
    required this.leafColor,
    required this.leafAccentColor,
    required this.wheatColor,
    required this.wheatAccentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Paints
    final leafPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [leafAccentColor, leafColor],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final leafShadePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [leafColor, AppColors.darkForest],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final wheatPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [wheatAccentColor, wheatColor],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final wheatStemPaint = Paint()
      ..color = wheatColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final leafVeinPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    // 1. Draw Main Green Leaf on Left side
    final leafPath = Path();
    leafPath.moveTo(w * 0.48, h * 0.06); // Tip of leaf
    leafPath.cubicTo(
      w * 0.15, h * 0.18, // Control 1
      w * 0.06, h * 0.52, // Control 2
      w * 0.36, h * 0.82, // Bottom sweep
    );
    leafPath.cubicTo(
      w * 0.46, h * 0.65, // Inner control 1
      w * 0.55, h * 0.38, // Inner control 2
      w * 0.48, h * 0.06, // Back to tip
    );
    leafPath.close();
    canvas.drawPath(leafPath, leafPaint);

    // Leaf inner shadow/dimension crescent
    final leafShadePath = Path();
    leafShadePath.moveTo(w * 0.48, h * 0.06);
    leafShadePath.cubicTo(
      w * 0.32, h * 0.25,
      w * 0.22, h * 0.55,
      w * 0.36, h * 0.82,
    );
    leafShadePath.cubicTo(
      w * 0.46, h * 0.65,
      w * 0.55, h * 0.38,
      w * 0.48, h * 0.06,
    );
    leafShadePath.close();
    canvas.drawPath(leafShadePath, leafShadePaint);

    // Leaf central vein line
    final veinPath = Path();
    veinPath.moveTo(w * 0.47, h * 0.12);
    veinPath.quadraticBezierTo(w * 0.34, h * 0.45, w * 0.34, h * 0.76);
    canvas.drawPath(veinPath, leafVeinPaint);

    // 2. Draw Wheat Stalk & Grains on Right side
    // Stem arch sweeping down and left
    final stemPath = Path();
    stemPath.moveTo(w * 0.72, h * 0.18);
    stemPath.cubicTo(
      w * 0.62, h * 0.46,
      w * 0.48, h * 0.78,
      w * 0.28, h * 0.94,
    );
    canvas.drawPath(stemPath, wheatStemPaint);

    // Wheat grains along the curve
    final List<Offset> grainPositions = [
      Offset(w * 0.70, h * 0.18), // Top grain
      Offset(w * 0.76, h * 0.28), // Right grain 1
      Offset(w * 0.59, h * 0.32), // Left grain 1
      Offset(w * 0.72, h * 0.42), // Right grain 2
      Offset(w * 0.53, h * 0.47), // Left grain 2
      Offset(w * 0.65, h * 0.57), // Right grain 3
      Offset(w * 0.46, h * 0.62), // Left grain 3
      Offset(w * 0.56, h * 0.70), // Right grain 4
    ];

    for (int i = 0; i < grainPositions.length; i++) {
      final pos = grainPositions[i];
      final isRight = i % 2 == 1 || i == 0;
      final grainSize = (w * 0.09) * (1.0 - (i * 0.035));
      final angle = (isRight ? 0.45 : -0.55) + (i * 0.06);

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(angle);

      // Draw grain kernel (teardrop / oval shape)
      final grainPath = Path();
      grainPath.moveTo(0, -grainSize);
      grainPath.cubicTo(
        grainSize * 0.9, -grainSize * 0.3,
        grainSize * 0.8, grainSize * 0.7,
        0, grainSize * 1.1,
      );
      grainPath.cubicTo(
        -grainSize * 0.8, grainSize * 0.7,
        -grainSize * 0.9, -grainSize * 0.3,
        0, -grainSize,
      );
      grainPath.close();

      canvas.drawPath(grainPath, wheatPaint);

      // Subtle grain center line
      final grainLinePaint = Paint()
        ..color = AppColors.accentWheat.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.015;
      canvas.drawLine(
        Offset(0, -grainSize * 0.7),
        Offset(0, grainSize * 0.7),
        grainLinePaint,
      );

      // Whiskers / awns for top grains
      if (i < 3) {
        final awnPaint = Paint()
          ..color = wheatAccentColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.018
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(0, -grainSize),
          Offset(isRight ? grainSize * 1.2 : -grainSize * 1.2, -grainSize * 2.2),
          awnPaint,
        );
      }

      canvas.restore();
    }

    // 3. Subtle connecting base sweep uniting leaf and wheat
    final baseSweep = Path();
    baseSweep.moveTo(w * 0.36, h * 0.82);
    baseSweep.quadraticBezierTo(w * 0.58, h * 0.90, w * 0.74, h * 0.74);

    final sweepPaint = Paint()
      ..color = leafColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.04
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(baseSweep, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant LeafWheatPainter oldDelegate) {
    return oldDelegate.leafColor != leafColor ||
        oldDelegate.leafAccentColor != leafAccentColor ||
        oldDelegate.wheatColor != wheatColor ||
        oldDelegate.wheatAccentColor != wheatAccentColor;
  }
}
