import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../services/db_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, double>? _categoryTotals;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final totals = await DbService.instance.sumByCategory();
    setState(() {
      _categoryTotals = totals;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _categoryTotals == null || _categoryTotals!.isEmpty
              ? const Center(child: Text('No data yet.'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Spending by Category',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 260,
                      child: PieChart(
                        PieChartData(
                          sections: _buildPieSections(),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ..._buildLegend(),
                  ],
                ),
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    final colors = [
      Colors.blue, Colors.orange, Colors.green, Colors.red,
      Colors.purple, Colors.teal, Colors.brown,
    ];
    final entries = _categoryTotals!.entries.toList();
    final total = entries.fold(0.0, (s, e) => s + e.value);
    return entries.indexed.map((pair) {
      final (i, entry) = pair;
      final pct = total > 0 ? entry.value / total * 100 : 0.0;
      return PieChartSectionData(
        color: colors[i % colors.length],
        value: entry.value,
        title: '${pct.toStringAsFixed(1)}%',
        radius: 80,
        titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
      );
    }).toList();
  }

  List<Widget> _buildLegend() {
    final colors = [
      Colors.blue, Colors.orange, Colors.green, Colors.red,
      Colors.purple, Colors.teal, Colors.brown,
    ];
    return _categoryTotals!.entries.indexed.map((pair) {
      final (i, entry) = pair;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Container(width: 16, height: 16, color: colors[i % colors.length]),
          const SizedBox(width: 8),
          Expanded(child: Text(entry.key)),
          Text('\$${entry.value.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
      );
    }).toList();
  }
}
