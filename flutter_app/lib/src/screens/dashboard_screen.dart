import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../theme/category_meta.dart';
import '../utils/currency.dart';
import '../utils/dates.dart';
import '../widgets/count_up_text.dart';
import '../widgets/donut_chart.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/icon_button_glass.dart';
import '../widgets/period_tile.dart';
import '../widgets/staggered_fade.dart';
import '../widgets/txn_row.dart';

class DashboardScreen extends ConsumerWidget {
  final VoidCallback onAdd;
  final void Function(Expense) onEdit;

  const DashboardScreen({
    super.key,
    required this.onAdd,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTxns = ref.watch(expensesProvider);
    return asyncTxns.when(
      loading: () => const _LoadingShim(),
      error: (e, _) =>
          Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.text2))),
      data: (txns) => _Body(txns: txns, onAdd: onAdd, onEdit: onEdit),
    );
  }
}

class _LoadingShim extends StatelessWidget {
  const _LoadingShim();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: AppColors.accent));
}

class _Body extends StatelessWidget {
  final List<Expense> txns;
  final VoidCallback onAdd;
  final void Function(Expense) onEdit;

  const _Body({required this.txns, required this.onAdd, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final today = txns.where((t) => isToday(t.createdAtDate)).toList();
    final week = txns.where((t) => isThisWeek(t.createdAtDate)).toList();
    final month = txns.where((t) => isThisMonth(t.createdAtDate)).toList();

    final todayTotal = today.fold<double>(0, (s, t) => s + t.amount);
    final weekTotal = week.fold<double>(0, (s, t) => s + t.amount);
    final monthTotal = month.fold<double>(0, (s, t) => s + t.amount);

    final byCat = <String, double>{};
    for (final t in month) {
      byCat[t.categoryId] = (byCat[t.categoryId] ?? 0) + t.amount;
    }
    final donut = byCat.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final donutTotal = donut.fold<double>(0, (s, e) => s + e.value);

    final recent = [...txns]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recent5 = recent.take(5).toList();

    final greet = _greeting();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StaggeredFade(child: _header(greet)),
          const SizedBox(height: 16),
          StaggeredFade(
            delay: const Duration(milliseconds: 80),
            child: _heroCard(context, todayTotal, today.length),
          ),
          const SizedBox(height: 16),
          StaggeredFade(
            delay: const Duration(milliseconds: 160),
            child: Row(
              children: [
                Expanded(
                  child: PeriodTile(
                    label: 'This week',
                    amount: weekTotal,
                    count: week.length,
                    delay: const Duration(milliseconds: 200),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PeriodTile(
                    label: 'This month',
                    amount: monthTotal,
                    count: month.length,
                    delay: const Duration(milliseconds: 280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          StaggeredFade(
            delay: const Duration(milliseconds: 240),
            child: _donutCard(donut, donutTotal),
          ),
          const SizedBox(height: 16),
          StaggeredFade(
            delay: const Duration(milliseconds: 320),
            child: _recent(context, recent5),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _header(String greet) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(greet,
                  style: const TextStyle(
                      color: AppColors.text3,
                      fontSize: 13,
                      letterSpacing: -0.1)),
              const SizedBox(height: 2),
              const Text('Welcome back',
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4)),
            ],
          ),
        ),
        const IconButtonGlass(icon: Icons.search),
        const SizedBox(width: 10),
        const IconButtonGlass(icon: Icons.calendar_today_outlined),
      ],
    );
  }

  Widget _heroCard(BuildContext context, double todayTotal, int count) {
    final today = DateTime.now();
    final dateLine = '${_weekday(today)}, ${_month(today)} ${today.day}';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -60,
          left: -40,
          right: -40,
          height: 200,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.4, -0.6),
                  radius: 0.7,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'SPENT TODAY',
                      style: TextStyle(
                          color: AppColors.text2,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4),
                    ),
                  ),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.accent2,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppColors.glow, blurRadius: 8),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dateLine.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.accent2,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 8, right: 6),
                    child: Text(
                      'PKR',
                      style: TextStyle(
                        color: AppColors.text2,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: CountUpText(
                      value: todayTotal,
                      delay: const Duration(milliseconds: 200),
                      formatter: (v) => _bigNumber(v),
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 44,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.8,
                        height: 1.05,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$count expense${count == 1 ? '' : 's'}',
                      style: const TextStyle(
                          color: AppColors.text3, fontSize: 12),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onAdd,
                      borderRadius: BorderRadius.circular(999),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          gradient: AppGradients.accent,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(color: AppColors.glow, blurRadius: 20),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 14, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'Add expense',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _donutCard(List<MapEntry<String, double>> donut, double total) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Where it went',
                        style: TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3)),
                    SizedBox(height: 2),
                    Text('This month',
                        style: TextStyle(
                            color: AppColors.text3, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0x0FFFFFFF),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  _month(DateTime.now()),
                  style: const TextStyle(
                      color: AppColors.text2,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (donut.isEmpty)
            EmptyState(label: 'No expenses this month yet', onAdd: onAdd)
          else
            LayoutBuilder(builder: (context, c) {
              final stack = c.maxWidth < 320;
              final chart = SizedBox(
                width: 150,
                height: 150,
                child: DonutChart(
                  data: donut
                      .map((e) => DonutSliceData(
                            label: metaFor(e.key).name,
                            value: e.value,
                            color: metaFor(e.key).color,
                          ))
                      .toList(),
                  size: 150,
                  stroke: 18,
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('TOTAL',
                          style: TextStyle(
                              color: AppColors.text3,
                              fontSize: 10,
                              letterSpacing: 0.4)),
                      const SizedBox(height: 2),
                      Text(
                        formatPkr(total, decimals: 0)
                            .replaceFirst('PKR ', ''),
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              );
              final legend = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: List.generate(donut.length.clamp(0, 5), (i) {
                  final e = donut[i];
                  final m = metaFor(e.key);
                  final pct = total > 0 ? (e.value / total) * 100 : 0;
                  return StaggeredFade(
                    delay: Duration(milliseconds: 500 + i * 80),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.5),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: m.color,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                    color: m.color.withOpacity(0.6),
                                    blurRadius: 6)
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              m.name,
                              style: const TextStyle(
                                  color: AppColors.text2, fontSize: 12),
                            ),
                          ),
                          Text(
                            '${pct.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              );
              if (stack) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [chart, const SizedBox(height: 16), legend],
                );
              }
              return Row(
                children: [
                  chart,
                  const SizedBox(width: 18),
                  Expanded(child: legend),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _recent(BuildContext context, List<Expense> recent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Text('Recent expenses',
                    style: TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3)),
              ),
              Text('Tap to edit',
                  style: TextStyle(color: AppColors.text3, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (recent.isEmpty)
          GlassCard(
            child: EmptyState(label: 'No expenses yet', onAdd: onAdd),
          )
        else
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < recent.length; i++) ...[
                  StaggeredFade(
                    delay: Duration(milliseconds: 400 + i * 60),
                    child: TxnRow(
                        expense: recent[i], onTap: () => onEdit(recent[i])),
                  ),
                  if (i != recent.length - 1)
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
    );
  }

  static String _weekday(DateTime d) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[d.weekday - 1];
  }

  static String _month(DateTime d) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return m[d.month - 1];
  }

  static String _bigNumber(double v) {
    final s = v.toStringAsFixed(2);
    final parts = s.split('.');
    final ints = parts[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '$ints.${parts[1]}';
  }
}
