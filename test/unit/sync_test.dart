import 'package:flutter_test/flutter_test.dart';
import 'package:pawcket/providers/settings_provider.dart';

void main() {
  group('SettingsState Sync Properties Tests', () {
    test('Initial sync values are correct', () {
      final state = SettingsState.initial();
      expect(state.lastSyncTime, isNull);
      expect(state.isSyncing, isFalse);
    });

    test('copyWith updates lastSyncTime and isSyncing correctly', () {
      final state = SettingsState.initial();
      final now = DateTime.now();
      
      final updated = state.copyWith(
        lastSyncTime: now,
        isSyncing: true,
      );

      expect(updated.lastSyncTime, equals(now));
      expect(updated.isSyncing, isTrue);

      final updatedBack = updated.copyWith(
        isSyncing: false,
      );

      expect(updatedBack.lastSyncTime, equals(now));
      expect(updatedBack.isSyncing, isFalse);
    });
  });
}
