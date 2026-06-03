import 'package:flutter_test/flutter_test.dart';
import 'package:pawcket/models/dashboard_data.dart';

void main() {
  test('CategoryBreakdown maps correctly', () {
    const cb = CategoryBreakdown(
      categoryId: 1,
      categoryName: 'food',
      colorHex: '#FF97316',
      iconName: 'food',
      totalAmount: 15000,
      percentage: 100.0,
    );
    expect(cb.categoryId, equals(1));
    expect(cb.percentage, equals(100.0));
  });
}
