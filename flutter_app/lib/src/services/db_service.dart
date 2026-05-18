import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../bridge/api.dart' as api;
import '../models/expense.dart';

class DbService {
  DbService._();
  static final DbService instance = DbService._();

  int? _handle;

  Future<void> init() async {
    if (_handle != null) return;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = '${dir.path}/expense_db';
    await Directory(dbPath).create(recursive: true);
    _handle = await api.openDb(path: dbPath);
  }

  Future<String> insertExpense({
    required double amount,
    required String category,
    required String description,
    required String date,
  }) {
    return api.insertExpense(
      handle: _handle!,
      amount: amount,
      category: category,
      description: description,
      date: date,
    );
  }

  Future<List<Expense>> queryExpenses({
    String? whereCategory,
    String? orderBy,
    int? limit,
  }) async {
    final conditions = <String>[];
    if (whereCategory != null) {
      conditions.add("category = '${whereCategory.replaceAll("'", "''")}'");
    }
    final where = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
    final order = orderBy != null ? 'ORDER BY $orderBy DESC' : '';
    final lim = limit != null ? 'LIMIT $limit' : '';
    final sql = 'SELECT * FROM expenses $where $order $lim'.trim();

    final rows = await api.queryExpenses(handle: _handle!, sqlText: sql);
    return rows
        .map((r) => Expense(
              id: r.id,
              amount: r.amount,
              category: r.category,
              description: r.description,
              date: r.date,
              createdAt: r.createdAt,
            ))
        .toList();
  }

  /// Sums per *normalized* category id (legacy `Housing`/`Entertainment`
  /// folded into `bills`/`leisure`). Keys are category ids like `food`.
  Future<Map<String, double>> sumByCategory() async {
    final rows = await queryExpenses();
    final map = <String, double>{};
    for (final e in rows) {
      final k = e.categoryId;
      map[k] = (map[k] ?? 0) + e.amount;
    }
    return map;
  }

  Future<void> deleteExpense(String id) {
    return api.deleteExpense(handle: _handle!, id: id);
  }

  void dispose() {
    if (_handle != null) {
      api.closeDb(handle: _handle!);
      _handle = null;
    }
  }
}
