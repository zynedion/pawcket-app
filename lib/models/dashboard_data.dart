class DashboardData {
  final int totalIncome;
  final int totalExpense;
  final int net;
  final int cumulativeBalance;
  final int totalTransactions;
  final List<CategoryBreakdown> categoryBreakdown;
  final List<TransactionSummary> recentTransactions;
  final DateTime selectedMonth;
  final bool isLoading;
  final String? errorMessage;

  const DashboardData({
    required this.totalIncome,
    required this.totalExpense,
    required this.net,
    required this.cumulativeBalance,
    required this.totalTransactions,
    required this.categoryBreakdown,
    required this.recentTransactions,
    required this.selectedMonth,
    this.isLoading = false,
    this.errorMessage,
  });

  factory DashboardData.initial(DateTime month) {
    return DashboardData(
      totalIncome: 0,
      totalExpense: 0,
      net: 0,
      cumulativeBalance: 0,
      totalTransactions: 0,
      categoryBreakdown: const [],
      recentTransactions: const [],
      selectedMonth: month,
      isLoading: false,
    );
  }

  DashboardData copyWith({
    int? totalIncome,
    int? totalExpense,
    int? net,
    int? cumulativeBalance,
    int? totalTransactions,
    List<CategoryBreakdown>? categoryBreakdown,
    List<TransactionSummary>? recentTransactions,
    DateTime? selectedMonth,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DashboardData(
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      net: net ?? this.net,
      cumulativeBalance: cumulativeBalance ?? this.cumulativeBalance,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class CategoryBreakdown {
  final int categoryId;
  final String categoryName;
  final String colorHex;
  final String iconName;
  final int totalAmount;
  final double percentage;

  const CategoryBreakdown({
    required this.categoryId,
    required this.categoryName,
    required this.colorHex,
    required this.iconName,
    required this.totalAmount,
    required this.percentage,
  });
}

class TransactionSummary {
  final int transactionId;
  final String categoryName;
  final String colorHex;
  final String iconName;
  final String description;
  final int amountIdr;
  final DateTime transactionDate;
  final bool isSyncedToCloud;
  final String transactionType; // 'expense' or 'income'

  const TransactionSummary({
    required this.transactionId,
    required this.categoryName,
    required this.colorHex,
    required this.iconName,
    required this.description,
    required this.amountIdr,
    required this.transactionDate,
    required this.isSyncedToCloud,
    this.transactionType = 'expense',
  });
}
