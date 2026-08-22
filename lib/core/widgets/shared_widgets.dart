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
