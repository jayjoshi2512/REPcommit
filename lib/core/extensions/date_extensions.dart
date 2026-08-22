/// Date-related extension methods for RepCommit.
extension DateTimeExtensions on DateTime {
  /// Returns the date portion as YYYY-MM-DD string.
  String toLocalDateString() {
    return '${year.toString().padLeft(4, '0')}-'
        '${month.toString().padLeft(2, '0')}-'
        '${day.toString().padLeft(2, '0')}';
  }

  /// Returns true if this date is the same calendar day as [other].
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Returns true if this date is today.
  bool get isToday => isSameDay(DateTime.now());

  /// Returns true if this date is in the future.
  bool get isFutureDay {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisDay = DateTime(year, month, day);
    return thisDay.isAfter(today);
  }

  /// Returns the start of the day (midnight).
  DateTime get startOfDay => DateTime(year, month, day);

  /// Returns the day of the week where Monday = 0, Sunday = 6.
  int get weekdayIndex => weekday - 1;

  /// Returns a short day label (M, T, W, T, F, S, S).
  String get shortDayLabel {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[weekdayIndex];
  }

  /// Returns formatted time like "9:41 PM".
  String get formattedTime {
    final hour = this.hour > 12 ? this.hour - 12 : (this.hour == 0 ? 12 : this.hour);
    final period = this.hour >= 12 ? 'PM' : 'AM';
    final minute = this.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  /// Returns formatted date header like "21 AUG".
  String get formattedDateHeader {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return '${day.toString().padLeft(2, '0')} ${months[month - 1]}';
  }

  /// Returns "THU · AUG 21" style label.
  String get dayModalLabel {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return '${days[weekdayIndex]} · ${months[month - 1]} $day';
  }

  /// Returns a relative label like "Today", "Yesterday", or weekday name.
  String get relativeLabel {
    final now = DateTime.now();
    if (isSameDay(now)) return 'Today';
    if (isSameDay(now.subtract(const Duration(days: 1)))) return 'Yesterday';
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    return weekdays[weekdayIndex];
  }
}

/// Number formatting extensions.
extension NumberFormatting on int {
  /// Formats with commas for thousands.
  String get formatted {
    if (this < 1000) return toString();
    final str = toString();
    final buffer = StringBuffer();
    final len = str.length;
    for (var i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}
