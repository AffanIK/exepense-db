import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import '../services/db_service.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../utils/dates.dart';
import '../widgets/expense_modal.dart';
import '../widgets/floating_nav.dart';
import 'analytics_screen.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';

class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  int _tab = 0;

  void _openAdd() => _openModal(null);
  void _openEdit(Expense e) => _openModal(e);

  Future<void> _openModal(Expense? editing) async {
    await ExpenseModal.show(
      context,
      editing: editing,
      onSubmit: (draft) async {
        if (editing == null) {
          await DbService.instance.insertExpense(
            amount: draft.amount,
            category: draft.categoryId,
            description: draft.description,
            date: toIsoDate(draft.date),
          );
        } else {
          await DbService.instance.deleteExpense(editing.id);
          await DbService.instance.insertExpense(
            amount: draft.amount,
            category: draft.categoryId,
            description: draft.description,
            date: toIsoDate(draft.date),
          );
        }
        ref.invalidate(expensesProvider);
      },
      onDelete: editing == null
          ? null
          : () async {
              await DbService.instance.deleteExpense(editing.id);
              ref.invalidate(expensesProvider);
            },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final navBottom = mq.padding.bottom + 16;

    final tabs = <Widget>[
      DashboardScreen(onAdd: _openAdd, onEdit: _openEdit),
      TransactionsScreen(onAdd: _openAdd, onEdit: _openEdit),
      const AnalyticsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const _AmbientBackground(),
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: KeyedSubtree(
                    key: ValueKey(_tab),
                    child: tabs[_tab],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: navBottom,
            child: FloatingNav(
              index: _tab,
              onTap: (i) => setState(() => _tab = i),
              items: const [
                NavItem(id: 'dashboard', icon: Icons.home_outlined),
                NavItem(id: 'txns', icon: Icons.list_alt_outlined),
                NavItem(id: 'analytics', icon: Icons.bar_chart_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.cream, AppColors.bg2],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.6, -0.95),
                    radius: 0.9,
                    colors: [
                      AppColors.teal.withOpacity(0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.9, 0.85),
                    radius: 0.7,
                    colors: [
                      AppColors.butter.withOpacity(0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
