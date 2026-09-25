/// Human-friendly date and time formatting, shared by every screen so the
/// app never mixes "2026-09-14", "14/9/2026", and "Sep 14".
///
/// Two kinds of value need different handling:
/// * **Calendar days** (attendance and logbook dates, placement start and
///   end) are stored as midnight UTC of that day, so they're read in UTC —
///   converting them to local time would shift them a day for anyone west
///   of Greenwich.
/// * **Moments** (check-in times, when something was submitted) are real
///   instants and are shown in the viewer's local time.
abstract final class Formatters {
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static const _monthsLong = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// Short month name, 1-based: `month(9)` → "Sep".
  static String month(int month) => _months[month - 1];

  /// Full month and year: "September 2026".
  static String monthYear(DateTime date) =>
      '${_monthsLong[date.month - 1]} ${date.year}';

  /// A calendar day: "Tue, 22 Sep 2026".
  static String day(DateTime date) {
    final d = date.toUtc();
    return '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  /// A calendar day without the weekday: "22 Sep 2026".
  static String date(DateTime? date) {
    if (date == null) {
      return '—';
    }
    final d = date.toUtc();
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  /// A span of calendar days: "1 Jun – 30 Sep 2026".
  static String dateRange(DateTime start, DateTime end) {
    final s = start.toUtc();
    final e = end.toUtc();
    final startText = s.year == e.year
        ? '${s.day} ${_months[s.month - 1]}'
        : date(s);
    return '$startText – ${date(e)}';
  }

  /// A moment's local clock time: "09:14".
  static String time(DateTime moment) {
    final local = moment.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  /// A moment's local date and time: "22 Sep 2026, 09:14".
  static String dateTime(DateTime moment) {
    final local = moment.toLocal();
    return '${local.day} ${_months[local.month - 1]} ${local.year}, '
        '${time(local)}';
  }

  /// How long ago a moment was: "just now", "5 min ago", "3 h ago",
  /// "yesterday", then the date.
  static String relative(DateTime moment, {DateTime? now}) {
    final current = (now ?? DateTime.now()).toLocal();
    final local = moment.toLocal();
    final difference = current.difference(local);
    if (difference.inMinutes < 1) {
      return 'just now';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }
    if (difference.inHours < 24 && local.day == current.day) {
      return '${difference.inHours} h ago';
    }
    final yesterday = DateTime(current.year, current.month, current.day - 1);
    if (local.year == yesterday.year &&
        local.month == yesterday.month &&
        local.day == yesterday.day) {
      return 'yesterday, ${time(local)}';
    }
    return '${local.day} ${_months[local.month - 1]}'
        '${local.year == current.year ? '' : ' ${local.year}'}';
  }

  /// "1 day", "3 days".
  static String count(int value, String singular, [String? plural]) =>
      '$value ${value == 1 ? singular : (plural ?? '${singular}s')}';

  /// Today as a calendar day (midnight UTC), matching how attendance and
  /// logbook days are stored.
  static DateTime todayUtc() {
    final now = DateTime.now().toUtc();
    return DateTime.utc(now.year, now.month, now.day);
  }

  /// A time-of-day greeting for dashboards.
  static String greeting([DateTime? now]) {
    final hour = (now ?? DateTime.now()).hour;
    if (hour < 12) {
      return 'Good morning';
    }
    if (hour < 17) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }
}
