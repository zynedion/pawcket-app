import 'package:flutter_test/flutter_test.dart';
import 'package:pawcket/models/dashboard_data.dart';

void main() {
  group('Dashboard Models Formatting & Calculation Tests', () {
    test('Empty categories breakdown does not cause crash', () {
      final data = DashboardData.initial(DateTime.now());
      expect(data.categoryBreakdown, isEmpty);
      expect(data.recentTransactions, isEmpty);
      expect(data.totalIncome, equals(0));
    });
  });
}
