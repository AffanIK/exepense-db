import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import '../services/db_service.dart';
import 'add_expense_screen.dart';
import 'dashboard_screen.dart';

final expensesProvider = FutureProvider.autoDispose<List<Expense>>((ref) {
  return DbService.instance.queryExpenses(orderBy: 'created_at');
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expensesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            ),
          ),
        ],
      ),
      body: expenses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (rows) => rows.isEmpty
            ? const Center(child: Text('No expenses yet. Tap + to add one.'))
            : ListView.builder(
                itemCount: rows.length,
                itemBuilder: (ctx, i) {
                  final e = rows[i];
                  return Dismissible(
                    key: Key(e.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) async {
                      await DbService.instance.deleteExpense(e.id);
                      ref.invalidate(expensesProvider);
                    },
                    child: ListTile(
                      leading: CircleAvatar(child: Text(e.category[0])),
                      title: Text(e.description.isEmpty ? e.category : e.description),
                      subtitle: Text('${e.date}  •  ${e.category}'),
                      trailing: Text(
                        '\$${e.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
          ref.invalidate(expensesProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
