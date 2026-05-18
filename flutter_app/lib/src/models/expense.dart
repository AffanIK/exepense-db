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

  /// When this expense was created, as a wall-clock DateTime (uses
  /// `createdAt` for the time-of-day portion, since `date` is yyyy-MM-dd).
  DateTime get createdAtDate => DateTime.fromMillisecondsSinceEpoch(createdAt);

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
