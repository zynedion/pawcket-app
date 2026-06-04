import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/user_preferences.dart';
import '../services/database/local_db.dart';
import '../providers/onboarding_provider.dart';
import '../providers/category_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/chat_provider.dart';

class SettingsState {
  final UserPreferencesModel? preferences;
  final String? deviceId;
  final String? appVersion;
  final String? buildNumber;
  final DateTime? userCreatedAt;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastSyncTime;
  final bool isSyncing;

  SettingsState({
    this.preferences,
    this.deviceId,
    this.appVersion,
    this.buildNumber,
    this.userCreatedAt,
    required this.isLoading,
    this.errorMessage,
    this.lastSyncTime,
    this.isSyncing = false,
  });

  factory SettingsState.initial() {
    return SettingsState(
      isLoading: false,
      isSyncing: false,
    );
  }

  SettingsState copyWith({
    UserPreferencesModel? preferences,
    String? deviceId,
    String? appVersion,
    String? buildNumber,
    DateTime? userCreatedAt,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastSyncTime,
    bool? isSyncing,
  }) {
    return SettingsState(
      preferences: preferences ?? this.preferences,
      deviceId: deviceId ?? this.deviceId,
      appVersion: appVersion ?? this.appVersion,
      buildNumber: buildNumber ?? this.buildNumber,
      userCreatedAt: userCreatedAt ?? this.userCreatedAt,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Ref ref;
  final LocalDb _db = LocalDb.instance;

  SettingsNotifier(this.ref) : super(SettingsState.initial()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _db.getUser();
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'User not found. Complete onboarding first.',
        );
        return;
      }

      final prefs = await _db.getUserPreferences(user.userId!);
      final packageInfo = await PackageInfo.fromPlatform();
      final lastSync = await _db.getLastSyncTime(user.userId!);

      state = state.copyWith(
        preferences: prefs,
        deviceId: user.deviceId,
        appVersion: packageInfo.version,
        buildNumber: packageInfo.buildNumber,
        userCreatedAt: DateTime.fromMillisecondsSinceEpoch(user.createdAt),
        lastSyncTime: lastSync,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load settings: $e',
      );
    }
  }

  Future<void> updateVoiceInput(bool enable) async {
    final prefs = state.preferences;
    if (prefs == null) return;

    final updatedPrefs = prefs.copyWith(
      enableVoiceInput: enable,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    state = state.copyWith(preferences: updatedPrefs);
    try {
      await _db.updateUserPreferences(updatedPrefs);
    } catch (e) {
      // Rollback on error
      state = state.copyWith(
        preferences: prefs,
        errorMessage: 'Failed to update setting: $e',
      );
    }
  }

  Future<void> updateCloudSync(bool enable) async {
    final prefs = state.preferences;
    if (prefs == null) return;

    final updatedPrefs = prefs.copyWith(
      enableCloudSync: enable,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    state = state.copyWith(preferences: updatedPrefs);
    try {
      await _db.updateUserPreferences(updatedPrefs);
    } catch (e) {
      // Rollback on error
      state = state.copyWith(
        preferences: prefs,
        errorMessage: 'Failed to update setting: $e',
      );
    }
  }

  Future<void> syncNow() async {
    final user = await _db.getUser();
    if (user == null) return;

    state = state.copyWith(isSyncing: true);
    try {
      // Simulate sync delay of 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await _db.updateLastSyncTime(user.userId!, nowMs);
      
      state = state.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.fromMillisecondsSinceEpoch(nowMs),
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        errorMessage: 'Failed to sync: $e',
      );
    }
  }

  Future<void> clearChatHistory() async {
    final user = await _db.getUser();
    if (user == null) return;

    state = state.copyWith(isLoading: true);
    try {
      await ref.read(chatProvider.notifier).clearHistory();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to clear chat history: $e',
      );
    }
  }

  Future<void> resetAppData(BuildContext context) async {
    final user = await _db.getUser();
    if (user == null) return;

    state = state.copyWith(isLoading: true);
    try {
      // 1. Delete DB tables for user
      await _db.resetAppData(user.userId!);

      // 2. Clear SharedPreferences device_id
      final sp = await SharedPreferences.getInstance();
      await sp.remove('device_id');

      // 3. Invalidate all providers
      ref.invalidate(onboardingProvider);
      ref.invalidate(categoryProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(chatProvider);
      ref.invalidate(settingsProvider);

      state = SettingsState.initial();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to reset app data: $e',
      );
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref);
});
