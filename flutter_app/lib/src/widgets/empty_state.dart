import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final String label;
  final VoidCallback? onAdd;
  final String addLabel;

  const EmptyState({
    super.key,
    required this.label,
    this.onAdd,
    this.addLabel = 'Add first expense',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0x337C3AED), Color(0x117C3AED)],
              ),
              border: Border.all(color: const Color(0x527C3AED)),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.auto_awesome_outlined,
                size: 22, color: AppColors.accent2),
          ),
          const SizedBox(height: 12),
          Text(label,
              style: const TextStyle(color: AppColors.text2, fontSize: 14)),
          if (onAdd != null) ...[
            const SizedBox(height: 12),
            _GradientButton(label: addLabel, onTap: onAdd!),
          ],
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: AppGradients.accent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(color: AppColors.glow, blurRadius: 14, spreadRadius: 0),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, size: 12, color: Colors.white),
              const SizedBox(width: 5),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
