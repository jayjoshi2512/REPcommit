import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Section header matching the prototype's ".section-head" pattern.
///
/// ```
/// Forecast                    learned from 28 days
/// ```
class SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  final EdgeInsets padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(title, style: AppTypography.headingSmall.copyWith(color: AppColors.ink)),
          if (trailing != null)
            Text(
              trailing!,
              style: AppTypography.micro.copyWith(
                color: AppColors.inkFaint,
                textBaseline: TextBaseline.alphabetic,
              ),
            ),
        ],
      ),
    );
  }
}

/// Kicker label — small uppercase monospace label.
class KickerLabel extends StatelessWidget {
  final String text;
  final Color? color;

  const KickerLabel(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTypography.kicker.copyWith(color: color ?? AppColors.inkFaint),
    );
  }
}

/// Micro label — slightly smaller than kicker, used inside instruments.
class MicroLabel extends StatelessWidget {
  final String text;
  final Color? color;

  const MicroLabel(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTypography.micro.copyWith(color: color ?? AppColors.inkFaint),
    );
  }
}

/// Brand mark — the signature square with signal dot and slash.
class BrandMark extends StatelessWidget {
  final double size;

  const BrandMark({super.key, this.size = 31});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.panel2,
        border: Border.all(color: AppColors.lineStrong, width: 1),
      ),
      child: ClipRRect(
        child: Image.asset(
          'assets/images/REPcommit.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Stack(
            children: [
              Positioned(
                left: 5,
                top: 5,
                child: Container(width: 9, height: 9, color: AppColors.signal),
              ),
              Positioned(
                right: 5,
                bottom: 6,
                child: Transform(
                  transform: Matrix4.skewX(-0.49),
                  child: Container(width: 8, height: 2, color: AppColors.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state widget with branded messaging.
class EmptyState extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: AppTypography.bodySmall.copyWith(color: AppColors.inkFaint),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.signal, width: 1),
                ),
                child: Text(
                  actionLabel!,
                  style: AppTypography.mono.copyWith(
                    color: AppColors.signal,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Animated Infinity Symbol (∞) Loader.
class InfiniteSymbolLoader extends StatefulWidget {
  final double size;
  final Color? color;
  final String? label;

  const InfiniteSymbolLoader({
    super.key,
    this.size = 42,
    this.color,
    this.label,
  });

  @override
  State<InfiniteSymbolLoader> createState() => _InfiniteSymbolLoaderState();
}

class _InfiniteSymbolLoaderState extends State<InfiniteSymbolLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.color ?? AppColors.signal;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: Size(widget.size * 1.8, widget.size),
              painter: _InfinitySymbolPainter(
                progress: _controller.value,
                color: activeColor,
              ),
            );
          },
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 12),
          Text(
            widget.label!.toUpperCase(),
            style: AppTypography.monoSmall.copyWith(
              color: AppColors.inkFaint,
              fontSize: 10,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ],
    );
  }
}

class _InfinitySymbolPainter extends CustomPainter {
  final double progress;
  final Color color;

  _InfinitySymbolPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final scale = w * 0.42;

    // 1. Dark Base Track (Thin & crisp)
    final trackPaint = Paint()
      ..color = AppColors.lineStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path();
    const steps = 120;
    for (var i = 0; i <= steps; i++) {
      final t = (i / steps) * 2 * math.pi;
      final denom = 1 + math.sin(t) * math.sin(t);
      final x = center.dx + (scale * math.cos(t)) / denom;
      final y = center.dy + (scale * math.sin(t) * math.cos(t)) / denom;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, trackPaint);

    // 2. Breathing Central Halo (Subtle glow)
    final pulseFactor = 0.5 + 0.5 * math.sin(progress * 2 * math.pi);
    final auraPaint = Paint()
      ..color = color.withValues(alpha: 0.08 + 0.12 * pulseFactor)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 + 1.5 * pulseFactor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawPath(path, auraPaint);

    // 3. Sleek Thin Neon Laser Comet Trail
    const trailSegments = 20;
    for (var i = 0; i < trailSegments; i++) {
      final subProgress = (progress - (i * 0.015)) % 1.0;
      final t = (subProgress < 0 ? subProgress + 1.0 : subProgress) * 2 * math.pi;
      final denom = 1 + math.sin(t) * math.sin(t);
      final x = center.dx + (scale * math.cos(t)) / denom;
      final y = center.dy + (scale * math.sin(t) * math.cos(t)) / denom;

      final fadeRatio = 1.0 - (i / trailSegments);
      final segmentAlpha = (fadeRatio * fadeRatio * 0.95).clamp(0.0, 1.0);
      final segmentRadius = 2.5 * fadeRatio + 0.8;

      final trailGlow = Paint()
        ..color = color.withValues(alpha: segmentAlpha * 0.35)
        ..style = PaintingStyle.fill;

      final trailCore = Paint()
        ..color = (i == 0 ? Colors.white : color).withValues(alpha: segmentAlpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), segmentRadius * 1.3, trailGlow);
      canvas.drawCircle(Offset(x, y), segmentRadius, trailCore);
    }
  }

  @override
  bool shouldRepaint(covariant _InfinitySymbolPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
