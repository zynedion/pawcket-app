import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_data.dart';
import '../services/database/local_db.dart';
import '../models/transaction.dart';

class HistoryState {
  final List<TransactionSummary> transactions;
  final String searchQuery;
  final String typeFilter; // 'all' | 'expense' | 'income'
  final int? categoryFilter;
  final DateTime? startDate;
  final DateTime? endDate;
  final String sortBy; // 'date_desc' | 'date_asc'
  final bool isLoading;
  final bool hasMore;
  final int offset;
  final String? errorMessage;
  final TransactionSummary? recentlyDeletedTransaction; // for undo action

  const HistoryState({
    required this.transactions,
    required this.searchQuery,
    required this.typeFilter,
    this.categoryFilter,
    this.startDate,
    this.endDate,
    required this.sortBy,
    required this.isLoading,
    required this.hasMore,
    required this.offset,
    this.errorMessage,
    this.recentlyDeletedTransaction,
  });

  factory HistoryState.initial() {
    return const HistoryState(
      transactions: [],
      searchQuery: '',
      typeFilter: 'all',
      sortBy: 'date_desc',
      isLoading: false,
      hasMore: true,
      offset: 0,
    );
  }

  HistoryState copyWith({
    List<TransactionSummary>? transactions,
    String? searchQuery,
    String? typeFilter,
    int? categoryFilter,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
    bool? isLoading,
    bool? hasMore,
    int? offset,
    String? errorMessage,
    TransactionSummary? recentlyDeletedTransaction,
    bool clearCategoryFilter = false,
    bool clearDateRange = false,
    bool clearRecentlyDeleted = false,
  }) {
    return HistoryState(
      transactions: transactions ?? this.transactions,
      searchQuery: searchQuery ?? this.searchQuery,
      typeFilter: typeFilter ?? this.typeFilter,
      categoryFilter: clearCategoryFilter ? null : (categoryFilter ?? this.categoryFilter),
      startDate: clearDateRange ? null : (startDate ?? this.startDate),
      endDate: clearDateRange ? null : (endDate ?? this.endDate),
      sortBy: sortBy ?? this.sortBy,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
      errorMessage: errorMessage,
      recentlyDeletedTransaction: clearRecentlyDeleted ? null : (recentlyDeletedTransaction ?? this.recentlyDeletedTransaction),
    );
  }
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  final LocalDb db = LocalDb.instance;
  static const int _limit = 20;

  HistoryNotifier() : super(HistoryState.initial()) {
    loadTransactions();
  }

  Future<void> loadTransactions({bool refresh = true}) async {
    if (refresh) {
      state = state.copyWith(isLoading: true, offset: 0, hasMore: true, transactions: []);
    } else if (!state.hasMore || state.isLoading) {
      return;
    }

    try {
      final user = await db.getUser();
      if (user == null) {
        state = state.copyWith(isLoading: false, errorMessage: 'User belum terdaftar.');
        return;
      }

      final results = await db.getTransactionsFiltered(
        userId: user.userId!,
        searchQuery: state.searchQuery,
        transactionType: state.typeFilter,
        categoryId: state.categoryFilter,
        startDate: state.startDate,
        endDate: state.endDate,
        limit: _limit,
        offset: state.offset,
        sortBy: state.sortBy,
      );

      final List<TransactionSummary> mappedTxs = results.map((tx) {
        return TransactionSummary(
          transactionId: tx['transaction_id'] as int,
          categoryName: tx['category_name'] as String,
          colorHex: tx['color_hex'] as String? ?? '#6B7280',
          iconName: tx['icon_name'] as String? ?? 'other',
          description: tx['description'] as String? ?? tx['category_name'] as String,
          amountIdr: tx['amount_idr'] as int,
          transactionDate: DateTime.fromMillisecondsSinceEpoch(tx['transaction_date'] as int),
          isSyncedToCloud: (tx['is_synced_to_cloud'] as int? ?? 0) == 1,
          transactionType: tx['transaction_type'] as String? ?? 'expense',
        );
      }).toList();

      final hasMore = mappedTxs.length >= _limit;
      final newOffset = state.offset + mappedTxs.length;

      state = state.copyWith(
        transactions: refresh ? mappedTxs : [...state.transactions, ...mappedTxs],
        isLoading: false,
        hasMore: hasMore,
        offset: newOffset,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat riwayat: $e',
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadTransactions();
  }

  void setTypeFilter(String type) {
    state = state.copyWith(typeFilter: type);
    loadTransactions();
  }

  void setCategoryFilter(int? categoryId) {
    if (categoryId == null) {
      state = state.copyWith(clearCategoryFilter: true);
    } else {
      state = state.copyWith(categoryFilter: categoryId);
    }
    loadTransactions();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) {
      state = state.copyWith(clearDateRange: true);
    } else {
      state = state.copyWith(startDate: start, endDate: end);
    }
    loadTransactions();
  }

  void setSortBy(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
    loadTransactions();
  }

  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      typeFilter: 'all',
      clearCategoryFilter: true,
      clearDateRange: true,
      sortBy: 'date_desc',
    );
    loadTransactions();
  }

  /// Soft deletes a transaction.
  Future<bool> deleteTransaction(TransactionSummary tx) async {
    try {
      final user = await db.getUser();
      if (user == null) return false;

      final count = await db.softDeleteTransaction(tx.transactionId, user.userId!);
      if (count > 0) {
        state = state.copyWith(
          transactions: state.transactions.where((t) => t.transactionId != tx.transactionId).toList(),
          recentlyDeletedTransaction: tx,
        );
        return true;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Gagal menghapus transaksi: $e');
    }
    return false;
  }

  /// Restores recently deleted transaction.
  Future<bool> undoDelete() async {
    final tx = state.recentlyDeletedTransaction;
    if (tx == null) return false;

    try {
      final user = await db.getUser();
      if (user == null) return false;

      final count = await db.restoreTransaction(tx.transactionId, user.userId!);
      if (count > 0) {
        state = state.copyWith(clearRecentlyDeleted: true);
        await loadTransactions();
        return true;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Gagal memulihkan transaksi: $e');
    }
    return false;
  }

  /// Updates a transaction.
  Future<bool> updateTransaction({
    required int transactionId,
    required int categoryId,
    required int amountIdr,
    required String description,
    required DateTime date,
    String? vendorName,
    String? paymentMethod,
    required String transactionType,
  }) async {
    try {
      final user = await db.getUser();
      if (user == null) return false;

      final originalMap = await db.getTransactionWithCategory(transactionId);
      if (originalMap == null) return false;

      final now = DateTime.now().millisecondsSinceEpoch;
      
      final updatedTx = TransactionModel(
        transactionId: transactionId,
        userId: user.userId!,
        categoryId: categoryId,
        transactionType: transactionType,
        amountIdr: amountIdr,
        description: description,
        vendorName: vendorName,
        paymentMethod: paymentMethod,
        transactionDate: date.millisecondsSinceEpoch,
        createdAt: originalMap['created_at'] as int,
        updatedAt: now,
        isSyncedToCloud: false,
        nlpConfidence: (originalMap['nlp_confidence'] as num?)?.toDouble() ?? 1.0,
      );

      final count = await db.updateTransaction(updatedTx);
      if (count > 0) {
        await loadTransactions();
        return true;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Gagal memperbarui transaksi: $e');
    }
    return false;
  }

  /// Bulk import transactions.
  Future<bool> importTransactions(List<TransactionModel> transactions) async {
    try {
      await db.insertTransactionsBatch(transactions);
      await loadTransactions();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Gagal mengimpor transaksi: $e');
      return false;
    }
  }
}

final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  return HistoryNotifier();
});
