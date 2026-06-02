import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../models/category.dart';
import '../../providers/category_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../services/database/local_db.dart';
import '../../widgets/common/mr_oyen_avatar.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _resetOnboarding(BuildContext context, WidgetRef ref) async {
    final db = LocalDb.instance;
    final user = await db.getUser();
    if (user != null) {
      // Clear DB tables
      final database = await db.database;
      await database.delete('categories');
      await database.delete('user_preferences');
      await database.delete('users');
      
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('device_id');
      
      // Reset provider state
      ref.invalidate(onboardingProvider);
      ref.invalidate(categoryProvider);

      if (!context.mounted) return;

      // Navigate back to onboarding
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoryProvider);

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: const Text(
          'Pawcket Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.neutral900),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            tooltip: 'Reset Onboarding (Test Mode)',
            onPressed: () => _resetOnboarding(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.space4),
              // Mascot greeting
              Card(
                color: AppColors.neutral0,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  child: Row(
                    children: [
                      const MrOyenAvatar(size: 64),
                      const SizedBox(width: AppSpacing.space4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mr. Oyen says:',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.neutral500,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Meow! Onboarding complete! Ready to start tracking your money or do you want to keep overspending? 😼',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: AppColors.neutral900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space5),
              Text(
                'Your Active Categories',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                'These categories are stored in SQLite and will be used to parse transactions.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.space4),
              // Categories List
              Expanded(
                child: categoriesAsync.when(
                  data: (categories) {
                    if (categories.isEmpty) {
                      return const Center(child: Text('No categories found.'));
                    }
                    return ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final catColor = CategoryModel.getColor(cat.colorHex);
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.space2),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(AppSpacing.space2),
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                CategoryModel.getIconData(cat.iconName),
                                color: catColor,
                              ),
                            ),
                            title: Text(
                              cat.categoryName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.neutral900,
                              ),
                            ),
                            subtitle: Text(
                              cat.isDefault ? 'Default Category' : 'Custom Category',
                              style: theme.textTheme.bodySmall,
                            ),
                            trailing: cat.isDefault
                                ? null
                                : const Chip(
                                    label: Text('Custom', style: TextStyle(fontSize: 10)),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(
                    child: Text(
                      'Failed to load categories: $err',
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
