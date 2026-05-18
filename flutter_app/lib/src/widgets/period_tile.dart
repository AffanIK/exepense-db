import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/currency.dart';
import 'count_up_text.dart';
import 'glass_card.dart';

class PeriodTile extends StatelessWidget {
  final String label;
  final double amount;
  final int count;
  final Duration delay;

  const PeriodTile({
    super.key,
    required this.label,
    required this.amount,
    required this.count,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.text3,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          CountUpText(
            value: amount,
            delay: delay,
            formatter: (v) => formatPkr(v),
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count expense${count == 1 ? '' : 's'}',
            style: const TextStyle(color: AppColors.text3, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
