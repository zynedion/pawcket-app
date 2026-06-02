import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryDark = Color(0xFF4F46E5); // Darker indigo
  static const Color primaryLight = Color(0xFF818CF8); // Lighter indigo
  
  static const Color secondary = Color(0xFF0EA5E9); // Cyan
  static const Color secondaryDark = Color(0xFF06B6D4); // Darker cyan
  
  static const Color danger = Color(0xFFEF4444); // Red
  static const Color success = Color(0xFF10B981); // Green
  static const Color warning = Color(0xFFF59E0B); // Amber
  
  // Neutrals
  static const Color neutral0 = Color(0xFFFFFFFF); // Pure white
  static const Color neutral50 = Color(0xFFF9FAFB); // Almost white app bg
  static const Color neutral100 = Color(0xFFF3F4F6); // Light gray
  static const Color neutral200 = Color(0xFFE5E7EB); // Divider gray
  static const Color neutral500 = Color(0xFF6B7280); // Medium gray
  static const Color neutral700 = Color(0xFF374151); // Dark gray
  static const Color neutral900 = Color(0xFF111827); // Almost black
  
  // Category Colors
  static const Color categoryFood = Color(0xFFF97316); // Orange
  static const Color categoryTransport = Color(0xFF0284C7); // Blue
  static const Color categoryEntertainment = Color(0xFFA855F7); // Purple
  static const Color categoryUtilities = Color(0xFFEAB308); // Yellow
  static const Color categoryHealthcare = Color(0xFFEC4899); // Pink
  static const Color categoryShopping = Color(0xFF14B8A6); // Teal
  static const Color categoryHousing = Color(0xFF78716C); // Brown
  static const Color categoryOther = Color(0xFF6B7280); // Gray
}

class AppSpacing {
  static const double space0 = 0.0;
  static const double space1 = 4.0;
  static const double space2 = 8.0;
  static const double space3 = 12.0;
  static const double space4 = 16.0;
  static const double space5 = 20.0;
  static const double space6 = 24.0;
  static const double space7 = 28.0;
  static const double space8 = 32.0;
  static const double space10 = 40.0;
  static const double space12 = 48.0;
  static const double space16 = 64.0;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.neutral50,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.neutral0,
        secondary: AppColors.secondary,
        onSecondary: AppColors.neutral0,
        error: AppColors.danger,
        onError: AppColors.neutral0,
        surface: AppColors.neutral0,
        onSurface: AppColors.neutral900,
        outline: AppColors.neutral200,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: AppColors.neutral900,
          height: 1.2,
        ),
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.neutral900,
          height: 1.3,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.neutral900,
          height: 1.35,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.neutral900,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.neutral700,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.neutral900,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.neutral500,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.neutral0,
        elevation: 1.0,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.neutral100),
        ),
        margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.neutral0,
        contentPadding: const EdgeInsets.symmetric(
          vertical: AppSpacing.space3,
          horizontal: AppSpacing.space4,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.neutral200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.neutral200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        hintStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.neutral500,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.neutral0,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.space3,
            horizontal: AppSpacing.space5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
