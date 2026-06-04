import 'package:flutter/material.dart';

enum PredefinedCategory {
  // === Expense Categories ===
  food('Food', 'food', 'fastfood', '#F97316'),
  transport('Transport', 'transport', 'directions_car', '#0284C7'),
  entertainment('Entertainment', 'entertainment', 'theaters', '#A855F7'),
  utilities('Utilities', 'utilities', 'lightbulb', '#EAB308'),
  healthcare('Healthcare', 'healthcare', 'health_and_safety', '#EC4899'),
  shopping('Shopping', 'shopping', 'shopping_bag', '#14B8A6'),
  housing('Housing', 'housing', 'home', '#78716C'),
  social('Dana Sosial', 'social', 'volunteer_activism', '#F43F5E'),
  emergencyFund('Dana Darurat', 'emergency_fund', 'savings', '#3B82F6'),
  debt('Cicilan/Utang', 'debt', 'credit_card', '#EF4444'),
  investmentOut('Investasi', 'investment_out', 'show_chart', '#0EA5E9'),
  other('Other', 'other', 'category', '#6B7280'),

  // === Income Categories ===
  salary('Gaji', 'salary', 'account_balance_wallet', '#10B981'),
  bonus('Bonus', 'bonus', 'star', '#059669'),
  investment('Investasi', 'investment', 'trending_up', '#0D9488'),
  gift('Hadiah', 'gift', 'card_giftcard', '#7C3AED'),
  otherIncome('Pendapatan Lain', 'other_income', 'attach_money', '#16A34A');

  final String displayName;
  final String categoryType;
  final String iconName;
  final String colorHex;

  const PredefinedCategory(
    this.displayName,
    this.categoryType,
    this.iconName,
    this.colorHex,
  );

  /// Returns true if this category is used for income transactions.
  bool get isIncome => [
    'salary', 'bonus', 'investment', 'gift', 'other_income'
  ].contains(categoryType);

  /// Expense-only categories
  static List<PredefinedCategory> get expenseCategories =>
      PredefinedCategory.values.where((c) => !c.isIncome).toList();

  /// Income-only categories
  static List<PredefinedCategory> get incomeCategories =>
      PredefinedCategory.values.where((c) => c.isIncome).toList();

  /// Check whether a given categoryType string belongs to income
  static bool isIncomeType(String categoryType) => [
    'salary', 'bonus', 'investment', 'gift', 'other_income'
  ].contains(categoryType.toLowerCase());
}

class CategoryModel {
  final int? categoryId;
  final int userId;
  final String categoryName;
  final String categoryType;
  final String? iconName;
  final String? colorHex;
  final bool isDefault;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;

  CategoryModel({
    this.categoryId,
    required this.userId,
    required this.categoryName,
    required this.categoryType,
    this.iconName,
    this.colorHex,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'category_id': categoryId,
      'user_id': userId,
      'category_name': categoryName,
      'category_type': categoryType,
      'icon_name': iconName,
      'color_hex': colorHex,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      categoryId: map['category_id'] as int?,
      userId: map['user_id'] as int,
      categoryName: map['category_name'] as String,
      categoryType: map['category_type'] as String,
      iconName: map['icon_name'] as String?,
      colorHex: map['color_hex'] as String?,
      isDefault: (map['is_default'] as int) == 1,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
      deletedAt: map['deleted_at'] as int?,
    );
  }

  // Helper method to convert an IconName to Flutter IconData
  static IconData getIconData(String? iconName) {
    switch (iconName) {
      case 'fastfood':
        return Icons.fastfood;
      case 'directions_car':
        return Icons.directions_car;
      case 'theaters':
        return Icons.theaters;
      case 'lightbulb':
        return Icons.lightbulb;
      case 'health_and_safety':
        return Icons.health_and_safety;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'home':
        return Icons.home;
      case 'palette':
        return Icons.palette;
      case 'volunteer_activism':
        return Icons.volunteer_activism;
      case 'savings':
        return Icons.savings;
      case 'credit_card':
        return Icons.credit_card;
      case 'show_chart':
        return Icons.show_chart;
      // Income icons
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'star':
        return Icons.star;
      case 'trending_up':
        return Icons.trending_up;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'attach_money':
        return Icons.attach_money;
      default:
        return Icons.category;
    }
  }

  // Helper to convert color hex to Flutter Color
  static Color getColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) {
      return Colors.grey;
    }
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }
}
