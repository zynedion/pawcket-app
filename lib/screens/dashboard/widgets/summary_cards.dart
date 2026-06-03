import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class SummaryCards extends StatelessWidget {
  final int totalIncome;
  final int totalExpense;

  const SummaryCards({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
  });

  String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")} IDR';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Card(
            color: AppColors.neutral0,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pemasukan',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.neutral500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(totalIncome),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: Card(
            color: AppColors.neutral0,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pengeluaran',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.neutral500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(totalExpense),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
