import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../theme/category_meta.dart';
import '../utils/currency.dart';
import '../utils/dates.dart';
import '../widgets/bar_chart_card.dart';
import '../widgets/cat_tile.dart';
import '../widgets/count_up_text.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/icon_button_glass.dart';
import '../widgets/progress_bar.dart';
import '../widgets/staggered_fade.dart';

enum _Range { d, w, m, y }

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  _Range _range = _Range.w;

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
        data: (txns) => _body(context, txns),
      ),
    );
  }

  int get _days {
    switch (_range) {
      case _Range.d:
        return 1;
      case _Range.w:
        return 7;
      case _Range.m:
        return 30;
      case _Range.y:
        return 365;
    }
  }

  List<BarBucket> _buckets(List<Expense> txns) {
    if (_range == _Range.d) {
      return List.generate(6, (i) {
        final h0 = i * 4;
        final h1 = h0 + 4;
        final amount = txns.where((t) {
          if (!isToday(t.dayDate)) return false;
          final hr = t.createdAtDate.hour;
          return hr >= h0 && hr < h1;
        }).fold<double>(0, (s, t) => s + t.amount);
        return BarBucket(label: '${h0}h', amount: amount);
      });
    }
    if (_range == _Range.w) {
      return List.generate(7, (i) {
        final ref = DateTime.now().subtract(Duration(days: 6 - i));
        final start = DateTime(ref.year, ref.month, ref.day);
        final end = start.add(const Duration(days: 1));
        final amount = txns
            .where((t) =>
                !t.dayDate.isBefore(start) && t.dayDate.isBefore(end))
            .fold<double>(0, (s, t) => s + t.amount);
        return BarBucket(label: _weekday(start), amount: amount);
      });
    }
    if (_range == _Range.m) {
      return List.generate(4, (i) {
        final wIdx = 3 - i;
        final ref = DateTime.now().subtract(Duration(days: 7 * (wIdx + 1) - 1));
        final start = DateTime(ref.year, ref.month, ref.day);
        final end = start.add(const Duration(days: 7));
        final amount = txns
            .where((t) =>
                !t.dayDate.isBefore(start) && t.dayDate.isBefore(end))
            .fold<double>(0, (s, t) => s + t.amount);
        return BarBucket(label: 'W${4 - wIdx}', amount: amount);
      });
    }
    // year — 12 months
    final now = DateTime.now();
    return List.generate(12, (i) {
      final mIdx = 11 - i;
      final d = DateTime(now.year, now.month - mIdx, 1);
      final next = DateTime(d.year, d.month + 1, 1);
      final amount = txns
          .where((t) =>
              !t.dayDate.isBefore(d) && t.dayDate.isBefore(next))
          .fold<double>(0, (s, t) => s + t.amount);
      return BarBucket(label: _monthInitial(d), amount: amount);
    });
  }

  Widget _body(BuildContext context, List<Expense> txns) {
    final buckets = _buckets(txns);
    final cutoffRef = DateTime.now().subtract(Duration(days: _days));
    final cutoff = DateTime(cutoffRef.year, cutoffRef.month, cutoffRef.day);
    final rangeTxns =
        txns.where((t) => !t.dayDate.isBefore(cutoff)).toList();
    final total = rangeTxns.fold<double>(0, (s, t) => s + t.amount);
    final avg = total / (_days == 0 ? 1 : _days);

    final byCat = <String, double>{};
    for (final t in rangeTxns) {
      byCat[t.categoryId] = (byCat[t.categoryId] ?? 0) + t.amount;
    }
    final cats = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxCat = cats.fold<double>(1, (m, e) => e.value > m ? e.value : m);

    final peak = buckets.fold<BarBucket>(
        const BarBucket(label: '', amount: 0),
        (p, b) => b.amount > p.amount ? b : p);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StaggeredFade(child: _header()),
          const SizedBox(height: 18),
          StaggeredFade(
            delay: const Duration(milliseconds: 60),
            child: _rangeSegmented(),
          ),
          const SizedBox(height: 18),
          StaggeredFade(
            delay: const Duration(milliseconds: 120),
            child: _chartCard(total, avg, buckets, peak),
          ),
          const SizedBox(height: 18),
          StaggeredFade(
            delay: const Duration(milliseconds: 200),
            child: _topCategories(cats, maxCat),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: const [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Analytics',
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8)),
              SizedBox(height: 2),
              Text('Insights from your spending',
                  style: TextStyle(color: AppColors.text3, fontSize: 13)),
            ],
          ),
        ),
        IconButtonGlass(icon: Icons.calendar_today_outlined),
      ],
    );
  }

  Widget _rangeSegmented() {
    const items = [
      (_Range.d, 'Day'),
      (_Range.w, 'Week'),
      (_Range.m, 'Month'),
      (_Range.y, 'Year'),
    ];
    return GlassCard(
      padding: const EdgeInsets.all(4),
      radius: 14,
      child: Row(
        children: items.map((it) {
          final active = _range == it.$1;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _range = it.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: AppCurves.spring,
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _chartCard(
      double total, double avg, List<BarBucket> buckets, BarBucket peak) {
    final avgLabel = _range == _Range.d
        ? 'Hourly avg'
        : _range == _Range.w
            ? 'Daily avg'
            : _range == _Range.m
                ? 'Weekly avg'
                : 'Monthly avg';
    final avgValue = _range == _Range.d
        ? avg * _days / 6
        : _range == _Range.w
            ? avg
            : _range == _Range.m
                ? avg * 7
                : avg * 30;
    return GlassCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('TOTAL SPENT',
                        style: TextStyle(
                            color: AppColors.text3,
                            fontSize: 12,
                            letterSpacing: 0.4)),
                    const SizedBox(height: 4),
                    CountUpText(
                      value: total,
                      delay: const Duration(milliseconds: 200),
                      formatter: (v) => formatPkr(v),
                      style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(avgLabel.toUpperCase(),
                      style: const TextStyle(
                          color: AppColors.text3,
                          fontSize: 12,
                          letterSpacing: 0.4)),
                  const SizedBox(height: 4),
                  CountUpText(
                    value: avgValue,
                    delay: const Duration(milliseconds: 300),
                    formatter: (v) => formatPkr(v),
                    style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedBarChart(
            key: ValueKey(_range),
            data: buckets,
            height: 170,
            delay: const Duration(milliseconds: 300),
          ),
          if (peak.amount > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.10),
                border: Border.all(color: AppColors.accent.withOpacity(0.25)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(Icons.auto_awesome,
                        size: 16, color: AppColors.accent2),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.text2,
                          height: 1.45,
                          letterSpacing: -0.1,
                        ),
                        children: [
                          const TextSpan(text: 'Your highest '),
                          TextSpan(
                              text: _range == _Range.d
                                  ? 'window'
                                  : _range == _Range.w
                                      ? 'day'
                                      : _range == _Range.m
                                          ? 'week'
                                          : 'month'),
                          const TextSpan(text: ' was '),
                          TextSpan(
                              text: peak.label,
                              style: const TextStyle(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w600)),
                          const TextSpan(text: ' at '),
                          TextSpan(
                              text: formatPkr(peak.amount),
                              style: const TextStyle(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w600)),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _topCategories(List<MapEntry<String, double>> cats, double maxCat) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Top categories',
                    style: TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3)),
              ),
              Text('${cats.length} active',
                  style: const TextStyle(
                      color: AppColors.text3, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          if (cats.isEmpty)
            const EmptyState(label: 'No data in this range')
          else
            Column(
              children: List.generate(cats.length, (i) {
                final e = cats[i];
                final m = metaFor(e.key);
                final pct = (e.value / maxCat) * 100;
                return StaggeredFade(
                  delay: Duration(milliseconds: 300 + i * 80),
                  child: Padding(
                    padding: EdgeInsets.only(
                        bottom: i == cats.length - 1 ? 0 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            CatTile(categoryId: e.key, size: 32, radius: 10),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(m.name,
                                      style: const TextStyle(
                                          color: AppColors.text,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: -0.2)),
                                  const SizedBox(height: 1),
                                  Text(
                                    '${pct.toStringAsFixed(0)}% of top',
                                    style: const TextStyle(
                                        color: AppColors.text3, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              formatPkr(e.value),
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        AnimatedProgressBar(
                          pct: pct,
                          color: m.color,
                          delay: Duration(milliseconds: 400 + i * 80),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  static String _weekday(DateTime d) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[d.weekday - 1];
  }

  static String _monthInitial(DateTime d) {
    const m = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    return m[d.month - 1];
  }
}
