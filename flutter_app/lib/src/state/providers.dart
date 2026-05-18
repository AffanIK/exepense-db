import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget.dart';
import '../models/expense.dart';
import '../services/budget_service.dart';
import '../services/db_service.dart';

/// Source-of-truth list of expenses, ordered newest-first.
final expensesProvider = FutureProvider.autoDispose<List<Expense>>((ref) {
  return DbService.instance.queryExpenses(orderBy: 'created_at');
});

class BudgetsNotifier extends StateNotifier<List<Budget>> {
  BudgetsNotifier() : super(BudgetService.instance.all);

  Future<void> setLimit(String catId, double limit) async {
    await BudgetService.instance.setLimit(catId, limit);
    state = BudgetService.instance.all;
  }
}

final budgetsProvider =
    StateNotifierProvider<BudgetsNotifier, List<Budget>>((ref) {
  return BudgetsNotifier();
});
