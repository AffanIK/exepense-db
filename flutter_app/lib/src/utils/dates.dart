import 'package:intl/intl.dart';

DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime startOfWeek([DateTime? d]) {
  final base = _startOfDay(d ?? DateTime.now());
  // ISO week: Monday is start. weekday: 1=Mon..7=Sun
  return base.subtract(Duration(days: base.weekday - 1));
}

DateTime startOfMonth([DateTime? d]) {
  final base = d ?? DateTime.now();
  return DateTime(base.year, base.month, 1);
}

bool isToday(DateTime d) {
  final n = DateTime.now();
  return d.year == n.year && d.month == n.month && d.day == n.day;
}

bool isYesterday(DateTime d) {
  final y = _startOfDay(DateTime.now()).subtract(const Duration(days: 1));
  return _startOfDay(d) == y;
}

bool isThisWeek(DateTime d) => d.isAfter(startOfWeek().subtract(const Duration(milliseconds: 1)));

bool isThisMonth(DateTime d) => d.isAfter(startOfMonth().subtract(const Duration(milliseconds: 1)));

final _time = DateFormat('h:mm a');
final _shortDay = DateFormat('MMM d');
final _weekdayMD = DateFormat('EEE, MMM d');

/// "Today, 9:14 AM" / "Yesterday, 6:00 PM" / "May 14, 11:30 AM"
String formatWhen(DateTime d) {
  final t = _time.format(d);
  if (isToday(d)) return 'Today, $t';
  if (isYesterday(d)) return 'Yesterday, $t';
  return '${_shortDay.format(d)}, $t';
}

/// "Today" / "Yesterday" / "Wed, May 14"
String dayLabel(DateTime d) {
  if (isToday(d)) return 'Today';
  if (isYesterday(d)) return 'Yesterday';
  return _weekdayMD.format(d);
}

/// Just the time portion. Used inline after the day label in lists.
String timeOnly(DateTime d) => _time.format(d);

/// yyyy-MM-dd (the column we store in the DB).
String toIsoDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

/// Parse our stored yyyy-MM-dd into a DateTime at midnight.
DateTime parseIsoDate(String s) => DateFormat('yyyy-MM-dd').parseStrict(s);
