import 'package:flutter_test/flutter_test.dart';
import 'package:pawcket/providers/onboarding_provider.dart';

void main() {
  group('Onboarding Custom Category Validation Tests', () {
    late OnboardingNotifier notifier;

    setUp(() {
      notifier = OnboardingNotifier();
    });

    test('Empty category name validation', () {
      final result = notifier.validateCustomCategory('');
      expect(result, equals('Category name cannot be empty'));

      final resultSpaces = notifier.validateCustomCategory('   ');
      expect(resultSpaces, equals('Category name cannot be empty'));
    });

    test('Too long category name validation', () {
      final longName = 'A' * 31;
      final result = notifier.validateCustomCategory(longName);
      expect(result, equals('Category name cannot exceed 30 characters'));
    });

    test('Predefined category duplicate validation (case-insensitive)', () {
      // Predefined categories include 'Food', 'Transport', etc.
      final result1 = notifier.validateCustomCategory('Food');
      expect(result1, contains('already exists'));

      final result2 = notifier.validateCustomCategory('food');
      expect(result2, contains('already exists'));

      final result3 = notifier.validateCustomCategory('FOOD');
      expect(result3, contains('already exists'));
    });

    test('Custom category duplicate validation (case-insensitive)', () {
      // Add a custom category first
      notifier.addCustomCategory('Hobby');

      final result1 = notifier.validateCustomCategory('Hobby');
      expect(result1, contains('already exists'));

      final result2 = notifier.validateCustomCategory('hobby');
      expect(result2, contains('already exists'));

      final result3 = notifier.validateCustomCategory('HOBBY');
      expect(result3, contains('already exists'));
    });

    test('Valid category validation', () {
      final result = notifier.validateCustomCategory('Gym Membership');
      expect(result, isNull);
    });
  });
}
