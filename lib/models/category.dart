import 'package:flutter/material.dart';

enum PredefinedCategory {
  food('Food', 'food', 'fastfood', '#F97316'),
  transport('Transport', 'transport', 'directions_car', '#0284C7'),
  entertainment('Entertainment', 'entertainment', 'theaters', '#A855F7'),
  utilities('Utilities', 'utilities', 'lightbulb', '#EAB308'),
  healthcare('Healthcare', 'healthcare', 'health_and_safety', '#EC4899'),
  shopping('Shopping', 'shopping', 'shopping_bag', '#14B8A6'),
  housing('Housing', 'housing', 'home', '#78716C'),
  other('Other', 'other', 'category', '#6B7280');

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
