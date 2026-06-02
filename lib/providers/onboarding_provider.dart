import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../services/database/local_db.dart';

class OnboardingState {
  final bool isCompleted;
  final bool isLoading;
  final List<PredefinedCategory> selectedPredefined;
  final List<String> customCategories;
  final String? errorMessage;

  OnboardingState({
    required this.isCompleted,
    required this.isLoading,
    required this.selectedPredefined,
    required this.customCategories,
    this.errorMessage,
  });

  factory OnboardingState.initial() {
    return OnboardingState(
      isCompleted: false,
      isLoading: false,
      // Auto-select Food, Transport, and Entertainment by default
      selectedPredefined: [
        PredefinedCategory.food,
        PredefinedCategory.transport,
        PredefinedCategory.entertainment,
      ],
      customCategories: [],
      errorMessage: null,
    );
  }

  OnboardingState copyWith({
    bool? isCompleted,
    bool? isLoading,
    List<PredefinedCategory>? selectedPredefined,
    List<String>? customCategories,
    String? errorMessage,
  }) {
    return OnboardingState(
      isCompleted: isCompleted ?? this.isCompleted,
      isLoading: isLoading ?? this.isLoading,
      selectedPredefined: selectedPredefined ?? this.selectedPredefined,
      customCategories: customCategories ?? this.customCategories,
      errorMessage: errorMessage,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final LocalDb _db = LocalDb.instance;

  OnboardingNotifier() : super(OnboardingState.initial()) {
    checkOnboardingStatus();
  }

  Future<void> checkOnboardingStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _db.getUser();
      if (user != null && user.hasCompletedOnboarding) {
        state = state.copyWith(isCompleted: true, isLoading: false);
      } else {
        state = state.copyWith(isCompleted: false, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to verify onboarding state: $e',
      );
    }
  }

  void togglePredefinedCategory(PredefinedCategory category) {
    final currentList = List<PredefinedCategory>.from(state.selectedPredefined);
    if (currentList.contains(category)) {
      currentList.remove(category);
    } else {
      currentList.add(category);
    }
    state = state.copyWith(selectedPredefined: currentList);
  }

  String? validateCustomCategory(String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return 'Category name cannot be empty';
    }
    if (trimmedName.length > 30) {
      return 'Category name cannot exceed 30 characters';
    }

    // Check case-insensitive duplicates in predefined category display names
    for (var pre in PredefinedCategory.values) {
      if (pre.displayName.toLowerCase() == trimmedName.toLowerCase()) {
        return 'Category "${pre.displayName}" already exists';
      }
    }

    // Check case-insensitive duplicates in existing custom categories
    for (var custom in state.customCategories) {
      if (custom.toLowerCase() == trimmedName.toLowerCase()) {
        return 'Category "$custom" already exists';
      }
    }

    return null;
  }

  bool addCustomCategory(String name) {
    final error = validateCustomCategory(name);
    if (error != null) {
      state = state.copyWith(errorMessage: error);
      return false;
    }

    final currentCustoms = List<String>.from(state.customCategories);
    currentCustoms.add(name.trim());
    state = state.copyWith(customCategories: currentCustoms, errorMessage: null);
    return true;
  }

  void removeCustomCategory(String name) {
    final currentCustoms = List<String>.from(state.customCategories);
    currentCustoms.remove(name);
    state = state.copyWith(customCategories: currentCustoms);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<bool> completeOnboarding() async {
    final totalSelected = state.selectedPredefined.length + state.customCategories.length;
    if (totalSelected < 3) {
      state = state.copyWith(errorMessage: 'Please select at least 3 categories');
      return false;
    }

    state = state.copyWith(isLoading: true);

    try {
      // 1. Generate/Retrieve device ID
      final prefs = await SharedPreferences.getInstance();
      var deviceId = prefs.getString('device_id');
      if (deviceId == null) {
        deviceId = const Uuid().v4();
        await prefs.setString('device_id', deviceId);
      }

      // 2. Create User in SQLite
      final user = await _db.createUser(deviceId);
      final userId = user.userId!;

      // 3. Prepare Category Models
      final now = DateTime.now().millisecondsSinceEpoch;
      final List<CategoryModel> categoriesToSave = [];

      // Predefined categories selected by user
      for (var pre in state.selectedPredefined) {
        categoriesToSave.add(CategoryModel(
          userId: userId,
          categoryName: pre.displayName,
          categoryType: pre.categoryType,
          iconName: pre.iconName,
          colorHex: pre.colorHex,
          isDefault: true,
          createdAt: now,
          updatedAt: now,
        ));
      }

      // Custom categories entered by user
      for (var customName in state.customCategories) {
        categoriesToSave.add(CategoryModel(
          userId: userId,
          categoryName: customName,
          categoryType: 'custom_${customName.toLowerCase().replaceAll(' ', '_')}',
          iconName: 'palette', // Custom categories default to palette icon
          colorHex: '#6B7280', // Default custom color hex (neutral gray)
          isDefault: false,
          createdAt: now,
          updatedAt: now,
        ));
      }

      // 4. Save to Database
      await _db.saveCategories(userId, categoriesToSave);
      await _db.updateOnboardingCompleted(userId);

      state = state.copyWith(
        isLoading: false,
        isCompleted: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Database error: Failed to save onboarding data. $e',
      );
      return false;
    }
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});
