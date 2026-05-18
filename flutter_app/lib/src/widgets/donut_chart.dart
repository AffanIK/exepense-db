import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DonutSliceData {
  final String label;
  final double value;
  final Color color;
  const DonutSliceData(
      {required this.label, required this.value, required this.color});
}

/// Animated donut chart with a centered child overlay.
class DonutChart extends StatelessWidget {
  final List<DonutSliceData> data;
  final double size;
  final double stroke;
  final Duration delay;
  final Widget? center;

  const DonutChart({
    super.key,
    required this.data,
    this.size = 150,
    this.stroke = 18,
    this.delay = const Duration(milliseconds: 200),
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    final total = data.fold<double>(0, (s, d) => s + d.value);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 900) + delay,
            curve: Interval(
              delay.inMilliseconds == 0
                  ? 0
                  : delay.inMilliseconds /
                      (const Duration(milliseconds: 900) + delay)
                          .inMilliseconds
                          .toDouble(),
              1.0,
              curve: AppCurves.draw,
            ),
            builder: (context, t, _) {
              return PieChart(
                PieChartData(
                  startDegreeOffset: -90,
                  sectionsSpace: 2,
                  centerSpaceRadius: (size - stroke) / 2 - stroke / 2,
                  sections: _sections(t, total),
                ),
              );
            },
          ),
          if (center != null) center!,
        ],
      ),
    );
  }

  List<PieChartSectionData> _sections(double t, double total) {
    if (total <= 0) {
      return [
        PieChartSectionData(
          value: 1,
          radius: stroke,
          showTitle: false,
          color: const Color(0x0DFFFFFF),
        ),
      ];
    }
    return data.map((d) {
      return PieChartSectionData(
        value: d.value * t + (1 - t) * 0.0001,
        radius: stroke,
        showTitle: false,
        color: d.color,
      );
    }).toList();
  }
}
