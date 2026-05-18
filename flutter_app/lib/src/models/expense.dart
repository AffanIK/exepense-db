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

  static const List<String> categories = [
    'Food',
    'Transport',
    'Housing',
    'Health',
    'Entertainment',
    'Shopping',
    'Other',
  ];
}
