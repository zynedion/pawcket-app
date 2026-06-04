import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class SummaryCards extends StatelessWidget {
  final int totalIncome;
  final int totalExpense;
  final int totalTransactions;
  final int cumulativeBalance;

  const SummaryCards({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalTransactions,
    required this.cumulativeBalance,
  });

  String _formatCurrency(int amount) {
    final abs = amount.abs();
    final formatted = abs.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '${amount < 0 ? '-' : ''}Rp$formatted';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final netColor = cumulativeBalance >= 0 ? AppColors.success : AppColors.danger;
    final netIcon = cumulativeBalance >= 0 ? Icons.trending_up : Icons.trending_down;

    return Column(
      children: [
        Row(
          children: [
            // Card 1: Pemasukan (Income)
            Expanded(
              child: _SummaryCard(
                label: 'Pemasukan',
                value: _formatCurrency(totalIncome),
                valueColor: AppColors.success,
                icon: Icons.arrow_downward_rounded,
                iconColor: AppColors.success,
                iconBgColor: const Color(0xFFDCFCE7),
                theme: theme,
              ),
            ),
            const SizedBox(width: 8),
            // Card 2: Pengeluaran (Expense)
            Expanded(
              child: _SummaryCard(
                label: 'Pengeluaran',
                value: _formatCurrency(totalExpense),
                valueColor: AppColors.danger,
                icon: Icons.arrow_upward_rounded,
                iconColor: AppColors.danger,
                iconBgColor: const Color(0xFFFFE4E6),
                theme: theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Card 3: Total Transaksi
            Expanded(
              child: _SummaryCard(
                label: 'Transaksi',
                value: '$totalTransactions',
                valueColor: AppColors.primary,
                icon: Icons.receipt_long_rounded,
                iconColor: AppColors.primary,
                iconBgColor: const Color(0xFFE0E7FF),
                theme: theme,
                isCount: true,
              ),
            ),
            const SizedBox(width: 8),
            // Card 4: Saldo / Balance
            Expanded(
              child: _SummaryCard(
                label: 'Saldo',
                value: _formatCurrency(cumulativeBalance),
                valueColor: netColor,
                icon: netIcon,
                iconColor: netColor,
                iconBgColor: cumulativeBalance >= 0 ? const Color(0xFFDCFCE7) : const Color(0xFFFFE4E6),
                theme: theme,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final ThemeData theme;
  final bool isCount;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.theme,
    this.isCount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.neutral0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.neutral100, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            // Icon bubble
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            // Label + Value
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.neutral500,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: (isCount ? theme.textTheme.titleMedium : theme.textTheme.bodyMedium)?.copyWith(
                      color: valueColor,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
