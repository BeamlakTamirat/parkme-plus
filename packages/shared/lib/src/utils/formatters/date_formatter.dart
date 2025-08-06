import 'package:intl/intl.dart';

class DateFormatter {
  // Standard date formats
  static final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _dateTimeFormat =
      DateFormat('MMM dd, yyyy • hh:mm a');
  static final DateFormat _shortDateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dayFormat = DateFormat('EEEE');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');

  /// Format date only
  /// Example: "Jan 15, 2024"
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Format time only
  /// Example: "02:30 PM"
  static String formatTime(DateTime dateTime) {
    return _timeFormat.format(dateTime);
  }

  /// Format full date and time
  /// Example: "Jan 15, 2024 • 02:30 PM"
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }

  /// Format short date
  /// Example: "15/01/2024"
  static String formatShortDate(DateTime date) {
    return _shortDateFormat.format(date);
  }

  /// Format day name
  /// Example: "Monday"
  static String formatDay(DateTime date) {
    return _dayFormat.format(date);
  }

  /// Format month and year
  /// Example: "January 2024"
  static String formatMonthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }

  /// Format relative time (time ago)
  /// Example: "2 hours ago", "Yesterday", "Last week"
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return weeks == 1 ? 'Last week' : '$weeks weeks ago';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return months == 1 ? 'Last month' : '$months months ago';
      } else {
        final years = (difference.inDays / 365).floor();
        return years == 1 ? 'Last year' : '$years years ago';
      }
    } else if (difference.inHours > 0) {
      return difference.inHours == 1
          ? '1 hour ago'
          : '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1
          ? '1 minute ago'
          : '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  /// Format duration between two dates
  /// Example: "2h 30m"
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  /// Format time range
  /// Example: "09:00 AM - 05:00 PM"
  static String formatTimeRange(DateTime startTime, DateTime endTime) {
    return '${formatTime(startTime)} - ${formatTime(endTime)}';
  }

  /// Format date range
  /// Example: "Jan 15 - Jan 20, 2024"
  static String formatDateRange(DateTime startDate, DateTime endDate) {
    if (startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day) {
      return formatDate(startDate);
    }

    if (startDate.year == endDate.year && startDate.month == endDate.month) {
      return '${DateFormat('MMM dd').format(startDate)} - ${DateFormat('dd, yyyy').format(endDate)}';
    }

    return '${formatDate(startDate)} - ${formatDate(endDate)}';
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  /// Get display text for date (Today, Tomorrow, or formatted date)
  static String getDisplayDate(DateTime date) {
    if (isToday(date)) {
      return 'Today';
    } else if (isTomorrow(date)) {
      return 'Tomorrow';
    } else {
      return formatDate(date);
    }
  }
}
