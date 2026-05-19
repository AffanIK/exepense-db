import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import '../services/db_service.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../theme/category_meta.dart';
import '../utils/currency.dart';
import '../utils/dates.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/icon_button_glass.dart';
import '../widgets/staggered_fade.dart';
import '../widgets/txn_row.dart';

enum _Period { all, today, week, month }

class TransactionsScreen extends ConsumerStatefulWidget {
  final VoidCallback onAdd;
  final void Function(Expense) onEdit;
  const TransactionsScreen(
      {super.key, required this.onAdd, required this.onEdit});

  @override
  ConsumerState<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  _Period _period = _Period.all;
  String _cat = 'all';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(expensesProvider);
    return SizedBox.expand(
      child: async.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: AppColors.text2))),
        data: (txns) => _build(context, txns),
      ),
    );
  }

  Widget _build(BuildContext context, List<Expense> all) {
    final filtered = all.where((t) {
      switch (_period) {
        case _Period.today:
          if (!isToday(t.dayDate)) return false;
          break;
        case _Period.week:
          if (!isThisWeek(t.dayDate)) return false;
          break;
        case _Period.month:
          if (!isThisMonth(t.dayDate)) return false;
          break;
        case _Period.all:
          break;
      }
      if (_cat != 'all' && t.categoryId != _cat) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final total = filtered.fold<double>(0, (s, t) => s + t.amount);
    final groups = <String, List<Expense>>{};
    for (final t in filtered) {
      final k = dayLabel(t.dayDate);
      groups.putIfAbsent(k, () => []).add(t);
    }

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StaggeredFade(child: _header(filtered.length, total)),
              const SizedBox(height: 16),
              StaggeredFade(
                delay: const Duration(milliseconds: 60),
                child: _searchBar(),
              ),
              const SizedBox(height: 14),
              StaggeredFade(
                delay: const Duration(milliseconds: 110),
                child: _periodSegmented(),
              ),
              const SizedBox(height: 12),
              StaggeredFade(
                delay: const Duration(milliseconds: 160),
                child: _categoryPills(),
              ),
              const SizedBox(height: 18),
              if (filtered.isEmpty)
                GlassCard(
                  child: EmptyState(
                      label: 'No expenses match these filters',
                      onAdd: widget.onAdd),
                )
              else
                Column(
                  children: [
                    for (var gi = 0; gi < groups.length; gi++) ...[
                      _group(
                          groups.keys.elementAt(gi),
                          groups.values.elementAt(gi),
                          gi),
                      if (gi != groups.length - 1) const SizedBox(height: 18),
                    ],
                  ],
                ),
            ],
          ),
        ),
        Positioned(right: 22, bottom: 110, child: _fab()),
      ],
    );
  }

  Widget _header(int n, double total) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Expenses',
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8)),
              const SizedBox(height: 2),
              Text(
                '$n item${n == 1 ? '' : 's'} · ${formatPkr(total)}',
                style: const TextStyle(color: AppColors.text3, fontSize: 13),
              ),
            ],
          ),
        ),
        const IconButtonGlass(icon: Icons.tune),
      ],
    );
  }

  Widget _searchBar() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 14,
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.text3, size: 16),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Search expenses',
                style: TextStyle(color: AppColors.text3, fontSize: 14)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.pine.withOpacity(0.06),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('⌘K',
                style: TextStyle(
                    color: AppColors.text3,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _periodSegmented() {
    final items = const [
      (_Period.all, 'All'),
      (_Period.today, 'Today'),
      (_Period.week, 'This week'),
      (_Period.month, 'This month'),
    ];
    return GlassCard(
      padding: const EdgeInsets.all(4),
      radius: 14,
      child: Row(
        children: items.map((it) {
          final active = _period == it.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _period = it.$1),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: AppCurves.spring,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: active ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: active
                      ? [BoxShadow(color: AppColors.glow, blurRadius: 12)]
                      : null,
                ),
                child: Text(
                  it.$2,
                  style: TextStyle(
                    color: active ? Colors.white : AppColors.text2,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _categoryPills() {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          _pill('All categories', null, _cat == 'all',
              () => setState(() => _cat = 'all')),
          ...kCategories.map((c) {
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _pill(
                c.name,
                c,
                _cat == c.id,
                () => setState(() => _cat = c.id),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _pill(
      String label, CategoryMeta? meta, bool active, VoidCallback onTap) {
    final color = meta?.color ?? AppColors.accent;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: AppCurves.spring,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? (meta == null
                  ? AppColors.teal
                  : color.withOpacity(0.14))
              : Colors.white,
          border: Border.all(
            color: active
                ? (meta == null ? AppColors.teal : color)
                : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: (meta == null ? AppColors.teal : color)
                        .withOpacity(0.24),
                    blurRadius: 14,
                  )
                ]
              : [
                  BoxShadow(
                    color: AppColors.pine.withOpacity(0.04),
                    offset: const Offset(0, 2),
                    blurRadius: 6,
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (meta != null) ...[
              Icon(meta.icon,
                  size: 13,
                  color: active ? color : AppColors.text2),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: active
                    ? (meta == null ? Colors.white : color)
                    : AppColors.text2,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _group(String day, List<Expense> items, int gi) {
    final dayTotal = items.fold<double>(0, (s, t) => s + t.amount);
    return StaggeredFade(
      delay: Duration(milliseconds: 200 + gi * 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    day.toUpperCase(),
                    style: const TextStyle(
                        color: AppColors.text3,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4),
                  ),
                ),
                Text(
                  formatPkr(dayTotal),
                  style: const TextStyle(
                    color: AppColors.text3,
                    fontSize: 12,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  Dismissible(
                    key: ValueKey(items[i].id),
                    direction: DismissDirection.endToStart,
                    background: _dismissBg(),
                    onDismissed: (_) async {
                      await DbService.instance.deleteExpense(items[i].id);
                      ref.invalidate(expensesProvider);
                    },
                    child: TxnRow(
                      expense: items[i],
                      onTap: () => widget.onEdit(items[i]),
                    ),
                  ),
                  if (i != items.length - 1)
                    const Padding(
                      padding: EdgeInsets.only(left: 52),
                      child: Divider(
                          height: 1, thickness: 1, color: AppColors.border),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dismissBg() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: AppColors.expense.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.delete_outline, color: Colors.white),
    );
  }

  Widget _fab() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onAdd,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.accent,
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withOpacity(0.40),
                offset: const Offset(0, 10),
                blurRadius: 24,
              ),
            ],
            border: Border.all(color: AppColors.butter.withOpacity(0.4)),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}
