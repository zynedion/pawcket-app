import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../models/category.dart';
import '../../providers/onboarding_provider.dart';
import '../dashboard/dashboard_screen.dart';

class CategorySelectionScreen extends ConsumerStatefulWidget {
  const CategorySelectionScreen({super.key});

  @override
  ConsumerState<CategorySelectionScreen> createState() => _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends ConsumerState<CategorySelectionScreen> {
  final TextEditingController _customCategoryController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _customCategoryController.dispose();
    super.dispose();
  }

  void _showAddCustomDialog() {
    // Reset error when showing dialog
    ref.read(onboardingProvider.notifier).clearError();
    _customCategoryController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Consumer(
              builder: (context, ref, _) {
                final onboardingState = ref.watch(onboardingProvider);
                
                return AlertDialog(
                  backgroundColor: AppColors.neutral0,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    'Add Custom Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutral900,
                    ),
                  ),
                  content: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _customCategoryController,
                          decoration: InputDecoration(
                            hintText: 'e.g. Gym, Hobby, Books',
                            errorText: onboardingState.errorMessage,
                          ),
                          maxLength: 30,
                          autofocus: true,
                          onChanged: (_) {
                            // Clear error on typing
                            ref.read(onboardingProvider.notifier).clearError();
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.neutral500),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final name = _customCategoryController.text.trim();
                        final success = ref
                            .read(onboardingProvider.notifier)
                            .addCustomCategory(name);
                        
                        if (success) {
                          Navigator.of(context).pop();
                        } else {
                          // Force state rebuild in the dialog to show errorText
                          setDialogState(() {});
                        }
                      },
                      child: const Text('Add'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    final totalSelected = state.selectedPredefined.length + state.customCategories.length;
    final isContinueEnabled = totalSelected >= 3 && !state.isLoading;

    // Handle onboarding completion
    ref.listen<OnboardingState>(onboardingProvider, (previous, current) {
      if (current.isCompleted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      } else if (current.errorMessage != null && current.errorMessage != previous?.errorMessage) {
        // Show snackbar for database or system errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(current.errorMessage!),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.neutral900),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Headline text
              Text(
                'Personalize Your Categories',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              
              Text(
                'Select at least 3 expense categories to help Mr. Oyen track your spending. You can also add custom ones.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.neutral500,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: AppSpacing.space5),

              // Categories Grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.45,
                    crossAxisSpacing: AppSpacing.space3,
                    mainAxisSpacing: AppSpacing.space3,
                  ),
                  itemCount: PredefinedCategory.values.length + state.customCategories.length + 1,
                  itemBuilder: (context, index) {
                    // Case 1: Predefined Categories
                    if (index < PredefinedCategory.values.length) {
                      final category = PredefinedCategory.values[index];
                      final isSelected = state.selectedPredefined.contains(category);
                      final categoryColor = CategoryModel.getColor(category.colorHex);

                      return InkWell(
                        onTap: () => notifier.togglePredefinedCategory(category),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? AppColors.primary.withValues(alpha: 0.06) 
                                : AppColors.neutral0,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected 
                                  ? AppColors.primary 
                                  : AppColors.neutral200,
                              width: isSelected ? 2.0 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          padding: const EdgeInsets.all(AppSpacing.space3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: categoryColor.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(AppSpacing.space2),
                                    child: Icon(
                                      CategoryModel.getIconData(category.iconName),
                                      color: categoryColor,
                                      size: 20,
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                ],
                              ),
                              Text(
                                category.displayName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.neutral900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Case 2: Custom Categories
                    final customIndex = index - PredefinedCategory.values.length;
                    if (customIndex < state.customCategories.length) {
                      final customName = state.customCategories[customIndex];
                      
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2.0,
                          ),
                        ),
                        padding: const EdgeInsets.all(AppSpacing.space3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.neutral500.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(AppSpacing.space2),
                                  child: const Icon(
                                    Icons.palette,
                                    color: AppColors.neutral500,
                                    size: 20,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.cancel,
                                    color: AppColors.neutral500,
                                    size: 20,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => notifier.removeCustomCategory(customName),
                                ),
                              ],
                            ),
                            Text(
                              customName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.neutral900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    }

                    // Case 3: Add Custom Category Card
                    return InkWell(
                      onTap: _showAddCustomDialog,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            style: BorderStyle.solid,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              color: AppColors.primary,
                              size: 28,
                            ),
                            const SizedBox(height: AppSpacing.space2),
                            Text(
                              'Add Custom',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Status Summary + Continue Button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          totalSelected >= 3 ? Icons.check_circle_outline : Icons.info_outline,
                          color: totalSelected >= 3 ? AppColors.success : AppColors.neutral500,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$totalSelected categories selected (min 3 required)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: totalSelected >= 3 ? AppColors.success : AppColors.neutral700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isContinueEnabled
                            ? () => notifier.completeOnboarding()
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
                          child: state.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Continue',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
