import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Keyless delivery-route visualization: no Maps API key required.
/// Draws pickup → courier → dropoff progress driven by live status.
class RouteProgressMap extends StatelessWidget {
  final double progress;
  final String pickupLabel;
  final String dropoffLabel;
  final String statusLabel;

  const RouteProgressMap({
    super.key,
    required this.progress,
    this.pickupLabel = 'Farm pickup',
    this.dropoffLabel = 'Delivery point',
    this.statusLabel = '',
  });

  static double progressForOrderStatus(String status) {
    switch (status.toLowerCase().replaceAll(' ', '').replaceAll('_', '')) {
      case 'pending':
        return 0.0;
      case 'accepted':
      case 'confirmed':
        return 0.2;
      case 'assigned':
        return 0.35;
      case 'pickedup':
        return 0.55;
      case 'intransit':
      case 'in transit':
        return 0.8;
      case 'delivered':
      case 'completed':
        return 1.0;
      default:
        return 0.1;
    }
  }

  static double progressForJobStatus(String status) {
    switch (status) {
      case 'requested':
        return 0.05;
      case 'accepted':
        return 0.3;
      case 'pickedUp':
        return 0.55;
      case 'inTransit':
        return 0.8;
      case 'delivered':
        return 1.0;
      default:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  statusLabel.isEmpty ? '${(p * 100).round()}% en route' : statusLabel,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text('${(p * 100).round()}%',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(child: CustomPaint(painter: _RoutePainter(progress: p), child: Container())),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.agriculture_rounded, size: 14, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(child: Text(pickupLabel, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis)),
              const Icon(Icons.home_outlined, size: 14, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(dropoffLabel, textAlign: TextAlign.end, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  final double progress;
  _RoutePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 14.0;
    final y = size.height / 2;
    final start = Offset(pad, y);
    final end = Offset(size.width - pad, y);
    final mid1 = Offset(size.width * 0.35, y - 28);
    final mid2 = Offset(size.width * 0.65, y + 28);

    Path path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(mid1.dx, mid1.dy, mid2.dx, mid2.dy, end.dx, end.dy);

    // Remaining route (dashed grey).
    final bg = Paint()
      ..color = AppColors.outlineVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    _drawDashed(canvas, path, bg);

    // Completed portion (green).
    final done = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final m in path.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * progress.clamp(0.0, 1.0)), done);
    }

    // Pickup pin.
    _drawPin(canvas, start, AppColors.primary, Icons.agriculture_rounded);
    // Courier dot at progress.
    for (final m in path.computeMetrics()) {
      final pos = m.getTangentForOffset(m.length * progress.clamp(0.0, 1.0))?.position ?? start;
      canvas.drawCircle(pos, 9, Paint()..color = AppColors.primary.withValues(alpha: 0.2));
      canvas.drawCircle(pos, 5, Paint()..color = AppColors.primary);
    }
    // Dropoff pin.
    _drawPin(canvas, end,
        progress >= 1.0 ? AppColors.primary : AppColors.onSurfaceVariant, Icons.home_outlined);
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, (d + 6).clamp(0, m.length)), paint);
        d += 11;
      }
    }
  }

  void _drawPin(Canvas canvas, Offset c, Color color, IconData icon) {
    canvas.drawCircle(c, 11, Paint()..color = color.withValues(alpha: 0.15));
    canvas.drawCircle(c, 7, Paint()..color = color);
    final tp = TextPainter(
      text: TextSpan(text: String.fromCharCode(icon.codePoint), style: TextStyle(fontFamily: icon.fontFamily, fontSize: 9, color: const Color(0xFFFFFFFF))),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _RoutePainter old) => old.progress != progress;
}
