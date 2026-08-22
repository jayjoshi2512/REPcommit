import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/heatmap_calculator.dart';
import '../../../providers/app_providers.dart';

/// GitHub-style contribution calendar.
///
/// Full-year grid: ~53 week columns × 7 rows.
/// Past cells show intensity, future cells are empty/dark, today is outlined.
class HeatmapWidget extends ConsumerWidget {
  final String? trailingLabel;
  final void Function(HeatmapCell cell)? onCellTap;

  const HeatmapWidget({
    super.key,
    this.trailingLabel,
    this.onCellTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final calculator = ref.read(heatmapCalculatorProvider);
    final now = DateTime.now();

    // Build daily totals map for heatmap.
    final dailyTotals = <String, int>{};
    for (final entry in appState.dailyStats.entries) {
      dailyTotals[entry.key] = entry.value.totalPushUps;
    }

    final heatmapData = calculator.calculate(
      year: now.year,
      dailyTotals: dailyTotals,
      today: now,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.line, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Commit field',
                style: AppTypography.heading.copyWith(color: AppColors.ink),
              ),
              Text(
                trailingLabel ?? '${now.year} · year view',
                style: AppTypography.monoSmall.copyWith(color: AppColors.inkFaint),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Grid with day labels
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day labels column
              SizedBox(
                width: 20,
                child: Padding(
                  padding: const EdgeInsets.only(top: 13),
                  child: Column(
                    children: List.generate(7, (i) {
                      final label = switch (i) {
                        1 => 'Mon',
                        3 => 'Wed',
                        5 => 'Fri',
                        _ => '',
                      };
                      return SizedBox(
                        height: AppConstants.heatCellSize + AppConstants.heatCellGap,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            label,
                            style: AppTypography.monoTiny.copyWith(color: AppColors.inkFaint),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Scrollable grid
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true, // Show recent weeks first
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Month labels
                      SizedBox(
                        height: 12,
                        width: heatmapData.totalColumns *
                            (AppConstants.heatCellSize + AppConstants.heatCellGap),
                        child: Stack(
                          children: heatmapData.monthLabels.map((ml) {
                            return Positioned(
                              left: ml.column *
                                  (AppConstants.heatCellSize + AppConstants.heatCellGap),
                              child: Text(
                                ml.label,
                                style: AppTypography.monoTiny.copyWith(
                                  color: AppColors.inkFaint,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      // Cell grid
                      SizedBox(
                        width: heatmapData.totalColumns *
                            (AppConstants.heatCellSize + AppConstants.heatCellGap),
                        height: 7 * (AppConstants.heatCellSize + AppConstants.heatCellGap),
                        child: CustomPaint(
                          painter: _HeatmapPainter(
                            cells: heatmapData.cells,
                            cellSize: AppConstants.heatCellSize,
                            gap: AppConstants.heatCellGap,
                          ),
                          child: GestureDetector(
                            onTapDown: (details) {
                              if (onCellTap == null) return;
                              final cell = _hitTest(
                                details.localPosition,
                                heatmapData.cells,
                                AppConstants.heatCellSize,
                                AppConstants.heatCellGap,
                              );
                              if (cell != null) onCellTap!(cell);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Footer
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.line, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${heatmapData.activeDays} active days · ${_formatNumber(heatmapData.totalPushUps)} push-ups',
                    style: AppTypography.monoSmall.copyWith(color: AppColors.inkFaint),
                  ),
                  // Legend
                  Row(
                    children: [
                      Text('LESS ', style: AppTypography.monoTiny.copyWith(color: AppColors.inkFaint)),
                      ...[AppColors.heatEmpty, AppColors.heatL1, AppColors.heatL2, AppColors.heatL3, AppColors.heatL4]
                          .map((c) => Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 4),
                                color: c,
                              )),
                      Text(' MORE', style: AppTypography.monoTiny.copyWith(color: AppColors.inkFaint)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  HeatmapCell? _hitTest(
    Offset pos,
    List<HeatmapCell> cells,
    double cellSize,
    double gap,
  ) {
    final stride = cellSize + gap;
    final col = (pos.dx / stride).floor();
    final row = (pos.dy / stride).floor();
    if (row < 0 || row >= 7) return null;

    try {
      return cells.firstWhere(
        (c) => c.weekColumn == col && c.dayRow == row,
      );
    } catch (_) {
      return null;
    }
  }

  String _formatNumber(int n) {
    if (n < 1000) return '$n';
    return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
  }
}

/// Custom painter for the heatmap grid — avoids creating hundreds of widgets.
class _HeatmapPainter extends CustomPainter {
  final List<HeatmapCell> cells;
  final double cellSize;
  final double gap;

  _HeatmapPainter({
    required this.cells,
    required this.cellSize,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stride = cellSize + gap;

    for (final cell in cells) {
      final x = cell.weekColumn * stride;
      final y = cell.dayRow * stride;
      final rect = Rect.fromLTWH(x, y, cellSize, cellSize);

      // Fill color.
      Color fillColor;
      if (cell.isFuture) {
        fillColor = AppColors.heatFuture;
      } else {
        fillColor = AppColors.heatLevel(cell.level);
      }

      canvas.drawRect(rect, Paint()..color = fillColor);

      // Border for future cells.
      if (cell.isFuture) {
        canvas.drawRect(
          rect,
          Paint()
            ..color = AppColors.heatFutureBorder
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      } else {
        // Subtle border for all cells.
        canvas.drawRect(
          rect,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.025)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }

      // Today outline.
      if (cell.isToday) {
        canvas.drawRect(
          Rect.fromLTWH(x - 1, y - 1, cellSize + 2, cellSize + 2),
          Paint()
            ..color = AppColors.signal
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) {
    return cells != oldDelegate.cells;
  }
}
