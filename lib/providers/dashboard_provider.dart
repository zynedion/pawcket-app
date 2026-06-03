import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_data.dart';
import '../services/database/local_db.dart';

class DashboardNotifier extends StateNotifier<DashboardData> {
  final LocalDb _db = LocalDb.instance;
  int _offset = 0;
  static const int _limit = 10;
  bool _hasMore = true;

  DashboardNotifier() : super(DashboardData.initial(DateTime.now())) {
    loadDashboard();
  }

  bool get hasMore => _hasMore;

  String _formatMonthYear(DateTime dt) {
    final year = dt.year;
    final month = dt.month.toString().padLeft(2, '0');
    return '$year-$month';
  }

  Future<void> loadDashboard({bool refresh = true}) async {
    if (refresh) {
      _offset = 0;
      _hasMore = true;
      state = state.copyWith(isLoading: true);
    } else if (!_hasMore || state.isLoading) {
      return;
    }

    try {
      final user = await _db.getUser();
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'User not registered.',
        );
        return;
      }

      final monthStr = _formatMonthYear(state.selectedMonth);
      final summary = await _db.getMonthlySummary(user.userId!, monthStr);
      final breakdowns = await _db.getCategoryBreakdown(user.userId!, monthStr);
      final txList = await _db.getTransactionsForMonth(
        user.userId!, 
        monthStr, 
        limit: _limit, 
        offset: _offset,
      );

      final List<CategoryBreakdown> mappedBreakdowns = breakdowns.map((b) {
        return CategoryBreakdown(
          categoryId: b['category_id'] as int,
          categoryName: b['category_name'] as String,
          colorHex: b['color_hex'] as String? ?? '#6B7280',
          iconName: b['icon_name'] as String? ?? 'other',
          totalAmount: b['total_amount'] as int? ?? 0,
          percentage: (b['percentage'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();

      final List<TransactionSummary> mappedTxs = txList.map((tx) {
        return TransactionSummary(
          transactionId: tx['transaction_id'] as int,
          categoryName: tx['category_name'] as String,
          colorHex: tx['color_hex'] as String? ?? '#6B7280',
          iconName: tx['icon_name'] as String? ?? 'other',
          description: tx['description'] as String? ?? tx['category_name'] as String,
          amountIdr: tx['amount_idr'] as int,
          transactionDate: DateTime.fromMillisecondsSinceEpoch(tx['transaction_date'] as int),
          isSyncedToCloud: (tx['is_synced_to_cloud'] as int? ?? 0) == 1,
        );
      }).toList();

      if (txList.length < _limit) {
        _hasMore = false;
      }

      if (refresh) {
        state = state.copyWith(
          totalIncome: summary['income'] ?? 0,
          totalExpense: summary['expense'] ?? 0,
          net: (summary['income'] ?? 0) - (summary['expense'] ?? 0),
          categoryBreakdown: mappedBreakdowns,
          recentTransactions: mappedTxs,
          isLoading: false,
        );
      } else {
        _offset += txList.length;
        state = state.copyWith(
          recentTransactions: [...state.recentTransactions, ...mappedTxs],
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat dashboard: $e',
      );
    }
  }

  Future<void> changeMonth(int offsetMonths) async {
    final currentMonth = state.selectedMonth;
    final newMonth = DateTime(currentMonth.year, currentMonth.month + offsetMonths, 1);
    
    // Limit to current month, user cannot select future months
    final now = DateTime.now();
    if (newMonth.isAfter(DateTime(now.year, now.month + 1, 0))) {
      return;
    }

    state = state.copyWith(selectedMonth: newMonth);
    await loadDashboard();
  }

  Future<void> loadMore() async {
    _offset = state.recentTransactions.length;
    await loadDashboard(refresh: false);
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardData>((ref) {
  return DashboardNotifier();
});
