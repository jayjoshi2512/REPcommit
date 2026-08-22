/// Heatmap data calculator.
///
/// Generates a full-year grid of cells for the GitHub-style
/// contribution calendar. Each cell carries its date, value,
/// intensity level, and positional metadata.
///
/// Intensity levels (0–4) are user-relative:
/// - Level 0: no activity
/// - Level 1: ≤ 25th percentile of the user's active days
/// - Level 2: ≤ 50th percentile
/// - Level 3: ≤ 75th percentile
/// - Level 4: > 75th percentile
class HeatmapCalculator {
  const HeatmapCalculator();

  /// Generate a full-year heatmap.
  ///
  /// Returns cells from the first Sunday on-or-before Jan 1 through
  /// the last Saturday on-or-after Dec 31, so the grid fills complete
  /// 7-row columns.
  HeatmapData calculate({
    required int year,
    required Map<String, int> dailyTotals,
    required DateTime today,
  }) {
    final jan1 = DateTime(year, 1, 1);
    final dec31 = DateTime(year, 12, 31);

    // Align to full weeks (Sunday-start columns).
    final start = jan1.subtract(Duration(days: jan1.weekday % 7));
    final end = dec31.add(Duration(days: (6 - dec31.weekday % 7) % 7));

    final totalDays = end.difference(start).inDays + 1;

    // Find max for normalization (only past/today cells).
    final pastValues = <int>[];
    for (var i = 0; i < totalDays; i++) {
      final date = start.add(Duration(days: i));
      if (date.isAfter(today)) continue;
      final key = _dateKey(date);
      final value = dailyTotals[key] ?? 0;
      if (value > 0) pastValues.add(value);
    }

    final maxValue = pastValues.isEmpty ? 1 : pastValues.reduce((a, b) => a > b ? a : b);

    // Build cells.
    final cells = <HeatmapCell>[];
    for (var i = 0; i < totalDays; i++) {
      final date = start.add(Duration(days: i));
      final key = _dateKey(date);
      final isFuture = date.isAfter(today);
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      final value = isFuture ? 0 : (dailyTotals[key] ?? 0);
      final level = isFuture ? 0 : _level(value, maxValue);

      cells.add(HeatmapCell(
        date: date,
        dateKey: key,
        value: value,
        level: level,
        isFuture: isFuture,
        isToday: isToday,
        weekColumn: i ~/ 7,
        dayRow: i % 7,
      ));
    }

    // Month label positions.
    final monthLabels = <MonthLabel>[];
    for (var m = 1; m <= 12; m++) {
      final firstOfMonth = DateTime(year, m, 1);
      final daysSinceStart = firstOfMonth.difference(start).inDays;
      final col = daysSinceStart ~/ 7;
      monthLabels.add(MonthLabel(month: m, column: col));
    }

    final activeDays = pastValues.length;
    final totalPushUps = pastValues.isEmpty ? 0 : pastValues.reduce((a, b) => a + b);

    return HeatmapData(
      cells: cells,
      monthLabels: monthLabels,
      totalColumns: (totalDays / 7).ceil(),
      activeDays: activeDays,
      totalPushUps: totalPushUps,
    );
  }

  /// Compute intensity level (0–4).
  int _level(int value, int maxValue) {
    if (value <= 0) return 0;
    final ratio = value / maxValue;
    if (ratio < 0.25) return 1;
    if (ratio < 0.50) return 2;
    if (ratio < 0.75) return 3;
    return 4;
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

class HeatmapData {
  final List<HeatmapCell> cells;
  final List<MonthLabel> monthLabels;
  final int totalColumns;
  final int activeDays;
  final int totalPushUps;

  const HeatmapData({
    required this.cells,
    required this.monthLabels,
    required this.totalColumns,
    required this.activeDays,
    required this.totalPushUps,
  });
}

class HeatmapCell {
  final DateTime date;
  final String dateKey;
  final int value;
  final int level; // 0-4
  final bool isFuture;
  final bool isToday;
  final int weekColumn;
  final int dayRow;

  const HeatmapCell({
    required this.date,
    required this.dateKey,
    required this.value,
    required this.level,
    required this.isFuture,
    required this.isToday,
    required this.weekColumn,
    required this.dayRow,
  });

  /// Accessibility label.
  String get semanticLabel {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final dateStr = '${months[date.month - 1]} ${date.day}, ${date.year}';
    if (isFuture) return '$dateStr. Future. No push-ups logged.';
    if (value == 0) return '$dateStr. No push-ups logged.';
    return '$dateStr. $value push-ups.';
  }
}

class MonthLabel {
  final int month; // 1-12
  final int column;

  const MonthLabel({required this.month, required this.column});

  String get label {
    const labels = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return labels[month - 1];
  }
}
