import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../theme/category_meta.dart';
import '../utils/currency.dart';
import '../utils/dates.dart';
import 'cat_tile.dart';

class TxnRow extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;

  const TxnRow({super.key, required this.expense, this.onTap});

  @override
  Widget build(BuildContext context) {
    final meta = metaFor(expense.category);
    final title =
        expense.description.isEmpty ? meta.name : expense.description;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              CatTile(categoryId: expense.categoryId),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${meta.name} · ${timeOnly(expense.createdAtDate)}',
                      style: const TextStyle(
                        color: AppColors.text3,
                        fontSize: 12,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatExpense(expense.amount),
                style: const TextStyle(
                  color: AppColors.expense,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
