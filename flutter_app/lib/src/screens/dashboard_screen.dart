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
import '../widgets/period_tile.dart';
import '../widgets/slip_logo.dart';
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
    return SizedBox.expand(
      child: asyncTxns.when(
        loading: () => const _LoadingShim(),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: AppColors.text2))),
        data: (txns) => _Body(txns: txns, onAdd: onAdd, onEdit: onEdit),
      ),
    );
  }
}

class _LoadingShim extends StatelessWidget {
  const _LoadingShim();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: AppColors.accent));
}

class _Body extends StatefulWidget {
  final List<Expense> txns;
  final VoidCallback onAdd;
  final void Function(Expense) onEdit;

  const _Body({required this.txns, required this.onAdd, required this.onEdit});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final txns = widget.txns;
    final week = txns.where((t) => isThisWeek(t.dayDate)).toList();
    final month = txns.where((t) => isThisMonth(t.dayDate)).toList();

    final weekTotal = week.fold<double>(0, (s, t) => s + t.amount);
    final monthTotal = month.fold<double>(0, (s, t) => s + t.amount);

    final now = DateTime.now();
    final dayCountSoFar = now.day.clamp(1, 31);
    final dailyAvg = month.isEmpty ? 0.0 : monthTotal / dayCountSoFar;

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
    final filteredRecent = _filter == 'all'
        ? recent
        : recent.where((t) => t.categoryId == _filter).toList();
    final shown = filteredRecent.take(10).toList();

    final greet = _greeting();

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 150),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StaggeredFade(child: _header(greet)),
              const SizedBox(height: 18),
              StaggeredFade(
                delay: const Duration(milliseconds: 80),
                child: _heroCard(context, monthTotal, month.length),
              ),
              const SizedBox(height: 12),
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: PeriodTile(
                        label: 'Daily avg',
                        amount: dailyAvg,
                        count: dayCountSoFar,
                        delay: const Duration(milliseconds: 280),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              StaggeredFade(
                delay: const Duration(milliseconds: 240),
                child: _donutCard(donut, donutTotal),
              ),
              const SizedBox(height: 16),
              StaggeredFade(
                delay: const Duration(milliseconds: 300),
                child: _filtersRow(),
              ),
              const SizedBox(height: 10),
              StaggeredFade(
                delay: const Duration(milliseconds: 340),
                child: _recent(context, shown),
              ),
            ],
          ),
        ),
        Positioned(right: 22, bottom: 110, child: _fab()),
      ],
    );
  }

  VoidCallback get onAdd => widget.onAdd;
  void Function(Expense) get onEdit => widget.onEdit;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _header(String greet) {
    final now = DateTime.now();
    final monthLabel = '${_month(now)} ${now.year}'.toUpperCase();
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(monthLabel,
                  style: const TextStyle(
                      color: AppColors.text3,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6)),
              const SizedBox(height: 4),
              Text(greet,
                  style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4)),
            ],
          ),
        ),
        const SlipMark(size: 40),
      ],
    );
  }

  Widget _heroCard(BuildContext context, double monthTotal, int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GlassCard(
          highlight: true,
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Butter glow in top-right
              Positioned(
                top: -68,
                right: -54,
                child: IgnorePointer(
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.butter.withOpacity(0.65),
                          AppColors.butter.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SPENT THIS MONTH',
                    style: TextStyle(
                        color: AppColors.text3,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 14, right: 6),
                        child: Text(
                          'Rs',
                          style: TextStyle(
                            color: AppColors.text3,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: CountUpText(
                          value: monthTotal,
                          delay: const Duration(milliseconds: 200),
                          formatter: (v) => _bigNumber(v),
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.8,
                            height: 1.05,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: AppColors.teal.withOpacity(0.30)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt_outlined,
                                size: 12, color: AppColors.tealDeep),
                            const SizedBox(width: 4),
                            Text(
                              '$count log${count == 1 ? '' : 's'}',
                              style: const TextStyle(
                                color: AppColors.tealDeep,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'tap + to log a new expense',
                          style: TextStyle(
                              color: AppColors.text3,
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
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

  Widget _filtersRow() {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          _filterChip(label: 'All', active: _filter == 'all', color: AppColors.teal,
              onTap: () => setState(() => _filter = 'all')),
          ...kCategories.map((c) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _filterChip(
                  label: c.name,
                  active: _filter == c.id,
                  color: c.color,
                  icon: c.icon,
                  onTap: () => setState(() => _filter = c.id),
                ),
              )),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool active,
    required Color color,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: AppCurves.spring,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.14) : Colors.white,
          border: Border.all(color: active ? color : AppColors.border),
          borderRadius: BorderRadius.circular(999),
          boxShadow: active
              ? [BoxShadow(color: color.withOpacity(0.20), blurRadius: 14)]
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
            if (icon != null) ...[
              Icon(icon, size: 14, color: active ? color : AppColors.text3),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: active ? color : AppColors.text2,
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

  Widget _fab() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.accent,
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withOpacity(0.45),
                offset: const Offset(0, 10),
                blurRadius: 28,
              ),
            ],
            border: Border.all(color: AppColors.butter.withOpacity(0.4)),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
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
                  color: AppColors.butter.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.butter),
                ),
                child: Text(
                  _month(DateTime.now()),
                  style: const TextStyle(
                      color: AppColors.pine,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4),
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
