class Budget {
  final String catId;
  final double limit;

  const Budget({required this.catId, required this.limit});

  Map<String, dynamic> toJson() => {'cat': catId, 'limit': limit};

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
        catId: json['cat'] as String,
        limit: (json['limit'] as num).toDouble(),
      );

  Budget copyWith({double? limit}) =>
      Budget(catId: catId, limit: limit ?? this.limit);
}

/// PKR defaults for first launch (rough monthly budgets for a single user).
const Map<String, double> kDefaultBudgetLimitsPkr = {
  'food': 30000,
  'transport': 15000,
  'shopping': 20000,
  'bills': 80000,
  'leisure': 10000,
  'health': 8000,
};
