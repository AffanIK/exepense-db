import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/currency.dart';

class BarBucket {
  final String label;
  final double amount;
  const BarBucket({required this.label, required this.amount});
}

class AnimatedBarChart extends StatelessWidget {
  final List<BarBucket> data;
  final double height;
  final Duration delay;

  const AnimatedBarChart({
    super.key,
    required this.data,
    this.height = 170,
    this.delay = const Duration(milliseconds: 150),
  });

  @override
  Widget build(BuildContext context) {
    final maxVal = data.fold<double>(
        1, (m, b) => b.amount > m ? b.amount : m);
    final peakIdx = _peakIndex();

    return SizedBox(
      height: height,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 800) + delay,
        curve: Interval(
          delay.inMilliseconds == 0
              ? 0
              : delay.inMilliseconds /
                  (const Duration(milliseconds: 800) + delay)
                      .inMilliseconds
                      .toDouble(),
          1.0,
          curve: AppCurves.draw,
        ),
        builder: (context, t, _) {
          return BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceBetween,
              maxY: maxVal * 1.15,
              barTouchData: BarTouchData(enabled: false),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (x, _) {
                      final i = x.toInt();
                      if (i < 0 || i >= data.length) return const SizedBox();
                      if (i != peakIdx) return const SizedBox();
                      final amt = data[i].amount;
                      if (amt <= 0) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          formatPkr(amt, decimals: 0).replaceFirst('PKR ', ''),
                          style: const TextStyle(
                            color: AppColors.accent2,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (x, _) {
                      final i = x.toInt();
                      if (i < 0 || i >= data.length) return const SizedBox();
                      final isPeak = i == peakIdx;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          data[i].label.toUpperCase(),
                          style: TextStyle(
                            color: isPeak ? AppColors.accent2 : AppColors.text3,
                            fontSize: 11,
                            fontWeight:
                                isPeak ? FontWeight.w600 : FontWeight.w500,
                            letterSpacing: 0.4,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: List.generate(data.length, (i) {
                final peak = i == peakIdx && data[i].amount > 0;
                final h = data[i].amount * t;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: h,
                      width: _barWidth(context, data.length),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8)),
                      gradient: peak
                          ? const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [AppColors.accent, AppColors.accent3],
                            )
                          : const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x1AFFFFFF),
                                Color(0x0AFFFFFF),
                              ],
                            ),
                      borderSide: peak
                          ? BorderSide.none
                          : const BorderSide(color: AppColors.border),
                    ),
                  ],
                );
              }),
            ),
          );
        },
      ),
    );
  }

  int _peakIndex() {
    if (data.isEmpty) return -1;
    int idx = 0;
    double v = data[0].amount;
    for (var i = 1; i < data.length; i++) {
      if (data[i].amount > v) {
        v = data[i].amount;
        idx = i;
      }
    }
    return v > 0 ? idx : -1;
  }

  double _barWidth(BuildContext context, int n) {
    final w = MediaQuery.of(context).size.width;
    final perBar = (w / n).clamp(20.0, 40.0);
    return perBar * 0.55;
  }
}
