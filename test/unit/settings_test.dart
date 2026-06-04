import 'package:flutter_test/flutter_test.dart';
import 'package:pawcket/models/user_preferences.dart';

void main() {
  group('UserPreferencesModel Tests', () {
    test('Serialization toMap and fromMap mapping test', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final prefs = UserPreferencesModel(
        preferenceId: 10,
        userId: 99,
        currencyCode: 'IDR',
        enableVoiceInput: false,
        enableCloudSync: true,
        enableNotifications: false,
        themeMode: 'dark',
        showTutorial: false,
        requirePinUnlock: true,
        requireBiometric: true,
        createdAt: now,
        updatedAt: now,
      );

      final map = prefs.toMap();
      expect(map['preference_id'], equals(10));
      expect(map['user_id'], equals(99));
      expect(map['currency_code'], equals('IDR'));
      expect(map['enable_voice_input'], equals(0));
      expect(map['enable_cloud_sync'], equals(1));
      expect(map['enable_notifications'], equals(0));
      expect(map['theme_mode'], equals('dark'));
      expect(map['show_tutorial'], equals(0));
      expect(map['require_pin_unlock'], equals(1));
      expect(map['require_biometric'], equals(1));
      expect(map['created_at'], equals(now));
      expect(map['updated_at'], equals(now));

      final deserialized = UserPreferencesModel.fromMap(map);
      expect(deserialized.preferenceId, equals(10));
      expect(deserialized.userId, equals(99));
      expect(deserialized.currencyCode, equals('IDR'));
      expect(deserialized.enableVoiceInput, isFalse);
      expect(deserialized.enableCloudSync, isTrue);
      expect(deserialized.enableNotifications, isFalse);
      expect(deserialized.themeMode, equals('dark'));
      expect(deserialized.showTutorial, isFalse);
      expect(deserialized.requirePinUnlock, isTrue);
      expect(deserialized.requireBiometric, isTrue);
      expect(deserialized.createdAt, equals(now));
      expect(deserialized.updatedAt, equals(now));
    });

    test('copyWith updates state correctly', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final prefs = UserPreferencesModel(
        userId: 1,
        enableVoiceInput: true,
        enableCloudSync: false,
        enableNotifications: true,
        createdAt: now,
        updatedAt: now,
      );

      final updated = prefs.copyWith(
        enableVoiceInput: false,
        enableCloudSync: true,
        themeMode: 'dark',
      );

      expect(updated.userId, equals(1));
      expect(updated.enableVoiceInput, isFalse);
      expect(updated.enableCloudSync, isTrue);
      expect(updated.themeMode, equals('dark'));
      expect(updated.enableNotifications, isTrue); // remains unchanged
      expect(updated.createdAt, equals(now));
    });
  });
}
