import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget.dart';
import '../models/expense.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../theme/category_meta.dart';
import '../utils/currency.dart';
import '../utils/dates.dart';
import '../widgets/cat_tile.dart';
import '../widgets/circular_progress_ring.dart';
import '../widgets/count_up_text.dart';
import '../widgets/glass_card.dart';
import '../widgets/icon_button_glass.dart';
import '../widgets/staggered_fade.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(expensesProvider);
    final budgets = ref.watch(budgetsProvider);
    return async.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent)),
      error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.text2))),
      data: (txns) => _body(context, txns, budgets),
    );
  }

  Widget _body(
      BuildContext context, List<Expense> txns, List<Budget> budgets) {
    final month = txns.where((t) => isThisMonth(t.createdAtDate)).toList();
    final byCat = <String, double>{};
    for (final t in month) {
      byCat[t.categoryId] = (byCat[t.categoryId] ?? 0) + t.amount;
    }

    final items = budgets
        .map((b) => (
              meta: metaFor(b.catId),
              limit: b.limit,
              spent: byCat[b.catId] ?? 0,
            ))
        .toList();
    final total = items.fold<double>(0, (s, b) => s + b.limit);
    final spent = items.fold<double>(0, (s, b) => s + b.spent);
    final left = total - spent;
    final pct = total <= 0 ? 0.0 : (spent / total) * 100;

    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final daysLeft = lastDay - now.day;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StaggeredFade(child: _header(now, daysLeft)),
          const SizedBox(height: 18),
          StaggeredFade(
            delay: const Duration(milliseconds: 80),
            child: _totalCard(total, spent, left, pct),
          ),
          const SizedBox(height: 18),
          StaggeredFade(
            delay: const Duration(milliseconds: 160),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text('By category',
                        style: TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3)),
                  ),
                  Text('Adjust',
                      style: TextStyle(
                          color: AppColors.accent2,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          StaggeredFade(
            delay: const Duration(milliseconds: 200),
            child: _grid(items),
          ),
        ],
      ),
    );
  }

  Widget _header(DateTime now, int daysLeft) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Budget',
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8)),
              const SizedBox(height: 2),
              Text(
                '${months[now.month - 1]} · $daysLeft day${daysLeft == 1 ? '' : 's'} remaining',
                style: const TextStyle(color: AppColors.text3, fontSize: 13),
              ),
            ],
          ),
        ),
        const IconButtonGlass(icon: Icons.edit_outlined),
      ],
    );
  }

  Widget _totalCard(double total, double spent, double left, double pct) {
    final overBudget = pct > 100;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -40,
          left: -30,
          right: -30,
          height: 180,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.4, -0.5),
                  radius: 0.8,
                  colors: [AppColors.glow, AppColors.glow.withOpacity(0)],
                ),
              ),
            ),
          ),
        ),
        GlassCard(
          highlight: true,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('MONTHLY BUDGET',
                            style: TextStyle(
                                color: AppColors.text2,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4)),
                        const SizedBox(height: 6),
                        CountUpText(
                          value: total,
                          delay: const Duration(milliseconds: 200),
                          formatter: (v) => formatPkr(v, decimals: 0),
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircularProgressRing(
                    pct: pct,
                    size: 72,
                    stroke: 7,
                    color: overBudget ? AppColors.expense : AppColors.accent2,
                    delay: const Duration(milliseconds: 300),
                    center: Text(
                      '${pct.round()}%',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('SPENT',
                            style: TextStyle(
                                color: AppColors.text3,
                                fontSize: 11,
                                letterSpacing: 0.3)),
                        const SizedBox(height: 2),
                        Text(
                          formatPkr(spent, decimals: 0),
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('REMAINING',
                          style: TextStyle(
                              color: AppColors.text3,
                              fontSize: 11,
                              letterSpacing: 0.3)),
                      const SizedBox(height: 2),
                      Text(
                        formatPkr(left.abs(), decimals: 0),
                        style: TextStyle(
                          color:
                              left >= 0 ? AppColors.income : AppColors.expense,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _grid(
      List<({CategoryMeta meta, double limit, double spent})> items) {
    return LayoutBuilder(builder: (context, c) {
      final single = c.maxWidth < 360;
      final cols = single ? 1 : 2;
      const gap = 12.0;
      final tileW =
          (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: List.generate(items.length, (i) {
          final it = items[i];
          final pct = it.limit <= 0 ? 0.0 : (it.spent / it.limit) * 100;
          final over = pct > 100;
          return SizedBox(
            width: tileW,
            child: StaggeredFade(
              delay: Duration(milliseconds: 260 + i * 70),
              child: GlassCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CatTile(
                            categoryId: it.meta.id, size: 34, radius: 11),
                        const Spacer(),
                        if (over)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.expenseBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text('OVER',
                                style: TextStyle(
                                  color: AppColors.expense,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                )),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircularProgressRing(
                          pct: pct,
                          size: 62,
                          stroke: 6,
                          color: it.meta.color,
                          delay: Duration(milliseconds: 400 + i * 80),
                          center: Text(
                            '${pct.round()}%',
                            style: TextStyle(
                              color: over ? AppColors.expense : AppColors.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(it.meta.name,
                                  style: const TextStyle(
                                      color: AppColors.text,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.2)),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontFeatures: [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                  children: [
                                    TextSpan(
                                      text:
                                          formatPkr(it.spent, decimals: 0),
                                      style: TextStyle(
                                          color: over
                                              ? AppColors.expense
                                              : AppColors.text2,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    TextSpan(
                                      text:
                                          ' / ${formatPkr(it.limit, decimals: 0)}',
                                      style: const TextStyle(
                                          color: AppColors.text4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      );
    });
  }
}
