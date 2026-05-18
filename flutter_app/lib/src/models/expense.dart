import '../theme/category_meta.dart';

class Expense {
  final String id;
  final double amount;
  final String category;
  final String description;
  final String date;
  final int createdAt;

  const Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    required this.createdAt,
  });

  /// Canonical category id (handles legacy `Housing`/`Entertainment` rows).
  String get categoryId => normalizeCategory(category);

  /// Wall-clock time the row was inserted. The FFI returns Unix seconds, so
  /// we scale to milliseconds here. Used for time-of-day display only —
  /// for date bucketing (today/week/month), use [dayDate] which reads
  /// the explicit `date` string the user chose.
  DateTime get createdAtDate =>
      DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);

  /// The expense's date as a DateTime at local midnight, parsed from the
  /// `yyyy-MM-dd` string. This is what isToday/isThisWeek/isThisMonth
  /// should be checked against.
  DateTime get dayDate {
    final parts = date.split('-');
    return DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  /// The 7 ids the UI works with.
  static const List<String> categories = <String>[
    'food',
    'shopping',
    'transport',
    'bills',
    'leisure',
    'health',
    'other',
  ];
}
