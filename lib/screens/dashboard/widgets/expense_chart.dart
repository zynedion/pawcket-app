import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../config/theme.dart';
import '../../../models/category.dart';
import '../../../models/dashboard_data.dart';

class ExpenseChart extends StatelessWidget {
  final List<CategoryBreakdown> breakdowns;
  final int totalExpense;

  const ExpenseChart({
    super.key,
    required this.breakdowns,
    required this.totalExpense,
  });

  String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")} IDR';
  }

  @override
  Widget build(BuildContext context) {
    if (breakdowns.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Card(
      color: AppColors.neutral0,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Proporsi Pengeluaran',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.space4),
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 60,
                      startDegreeOffset: -90,
                      sections: breakdowns.map((b) {
                        final color = CategoryModel.getColor(b.colorHex);
                        return PieChartSectionData(
                          color: color,
                          value: b.totalAmount.toDouble(),
                          title: '${b.percentage.toStringAsFixed(0)}%',
                          radius: 35,
                          titleStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total',
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.neutral500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatCurrency(totalExpense),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.neutral900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            // Legend
            Column(
              children: breakdowns.map((b) {
                final color = CategoryModel.getColor(b.colorHex);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        CategoryModel.getIconData(b.iconName),
                        size: 14,
                        color: AppColors.neutral500,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          b.categoryName,
                          style: const TextStyle(fontSize: 12, color: AppColors.neutral900, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        _formatCurrency(b.totalAmount),
                        style: const TextStyle(fontSize: 12, color: AppColors.neutral700, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
