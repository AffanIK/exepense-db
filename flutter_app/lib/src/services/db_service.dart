import 'dart:io';
import 'package:path_provider/path_provider.dart';

// Once flutter_rust_bridge codegen runs, replace this import:
// import '../bridge/frb_generated.dart';
import '../models/expense.dart';

/// Singleton service wrapping all Rust FFI calls.
/// Replace stub implementations with actual frb calls after codegen.
class DbService {
  DbService._();
  static final DbService instance = DbService._();

  int? _handle;

  Future<void> init() async {
    if (_handle != null) return;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = '${dir.path}/expense_db';
    await Directory(dbPath).create(recursive: true);

    // Replace with: _handle = await api.openDb(path: dbPath);
    _handle = 1; // stub
  }

  Future<String> insertExpense({
    required double amount,
    required String category,
    required String description,
    required String date,
  }) async {
    // Replace with: return api.insertExpense(handle: _handle!, amount: amount, ...);
    return 'stub-id';
  }

  Future<List<Expense>> queryExpenses({String? whereCategory, String? orderBy, int? limit}) async {
    final conditions = <String>[];
    if (whereCategory != null) conditions.add("category = '$whereCategory'");
    final where = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
    final order = orderBy != null ? 'ORDER BY $orderBy DESC' : '';
    final lim = limit != null ? 'LIMIT $limit' : '';
    final sql = 'SELECT * FROM expenses $where $order $lim'.trim();
    // Replace with: final rows = await api.queryExpenses(handle: _handle!, sqlText: sql);
    return []; // stub
  }

  Future<Map<String, double>> sumByCategory() async {
    // SELECT category FROM expenses GROUP BY category
    final rows = await queryExpenses();
    final map = <String, double>{};
    for (final e in rows) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  Future<void> deleteExpense(String id) async {
    // Replace with: await api.deleteExpense(handle: _handle!, id: id);
  }

  void dispose() {
    if (_handle != null) {
      // api.closeDb(handle: _handle!);
      _handle = null;
    }
  }
}
