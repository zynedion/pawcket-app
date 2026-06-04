import 'package:flutter_test/flutter_test.dart';
import 'package:pawcket/providers/history_provider.dart';
import 'package:pawcket/models/dashboard_data.dart';

void main() {
  group('HistoryState Unit Tests', () {
    test('Initial state values are correct', () {
      final state = HistoryState.initial();
      expect(state.transactions, isEmpty);
      expect(state.searchQuery, isEmpty);
      expect(state.typeFilter, equals('all'));
      expect(state.categoryFilter, isNull);
      expect(state.startDate, isNull);
      expect(state.endDate, isNull);
      expect(state.sortBy, equals('date_desc'));
      expect(state.isLoading, isFalse);
      expect(state.hasMore, isTrue);
      expect(state.offset, equals(0));
      expect(state.recentlyDeletedTransaction, isNull);
    });

    test('copyWith updates fields correctly', () {
      final state = HistoryState.initial();
      
      final updated = state.copyWith(
        searchQuery: 'makan',
        typeFilter: 'expense',
        sortBy: 'date_asc',
        isLoading: true,
        offset: 20,
      );

      expect(updated.searchQuery, equals('makan'));
      expect(updated.typeFilter, equals('expense'));
      expect(updated.sortBy, equals('date_asc'));
      expect(updated.isLoading, isTrue);
      expect(updated.offset, equals(20));
      
      // Other fields should remain their defaults
      expect(updated.categoryFilter, isNull);
      expect(updated.startDate, isNull);
    });

    test('copyWith clearing filters works correctly', () {
      final now = DateTime.now();
      final state = HistoryState(
        transactions: const [],
        searchQuery: 'test',
        typeFilter: 'income',
        categoryFilter: 5,
        startDate: now,
        endDate: now,
        sortBy: 'date_desc',
        isLoading: false,
        hasMore: true,
        offset: 10,
        recentlyDeletedTransaction: TransactionSummary(
          transactionId: 1,
          categoryName: 'Gaji',
          colorHex: '#10B981',
          iconName: 'wallet',
          description: 'Gaji',
          amountIdr: 5000000,
          transactionDate: now,
          isSyncedToCloud: false,
          transactionType: 'income',
        ),
      );

      // Clear category
      final clearedCat = state.copyWith(clearCategoryFilter: true);
      expect(clearedCat.categoryFilter, isNull);
      expect(clearedCat.startDate, equals(now));

      // Clear date range
      final clearedDates = state.copyWith(clearDateRange: true);
      expect(clearedDates.startDate, isNull);
      expect(clearedDates.endDate, isNull);
      expect(clearedDates.categoryFilter, equals(5));

      // Clear recently deleted
      final clearedDeleted = state.copyWith(clearRecentlyDeleted: true);
      expect(clearedDeleted.recentlyDeletedTransaction, isNull);
    });
  });
}
