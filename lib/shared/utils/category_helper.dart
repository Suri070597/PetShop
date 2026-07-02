import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';

/// Helper class to manage product categories consistently across the app.
/// 
/// Instead of hardcoding category IDs and names in multiple places,
/// use this single source of truth. When new categories are added to the DB,
/// just update the [_categories] map here.
class CategoryHelper {
  // Private constructor - utility class
  CategoryHelper._();

  /// Internal map: categoryId (String) -> category info
  static const Map<String, _CategoryInfo> _categories = {
    '1': _CategoryInfo('Thức ăn', AppColors.forest, Icons.restaurant),
    '2': _CategoryInfo('Phụ kiện', AppColors.coffee, Icons.checkroom_outlined),
    '3': _CategoryInfo('Đồ chơi', Color(0xFF875D4E), Icons.sports_baseball),
    '4': _CategoryInfo('Sức khỏe', AppColors.forest, Icons.medical_services_outlined),
  };

  /// Default fallback when category ID is not recognized.
  static const _CategoryInfo _defaultCategory = _CategoryInfo(
    'Chưa phân loại',
    AppColors.muted,
    Icons.category_outlined,
  );

  /// Get the display name for a category by its ID.
  /// Returns "Chưa phân loại" if the ID is not recognized.
  static String getName(String categoryId) {
    return _categories[categoryId]?.name ?? _defaultCategory.name;
  }

  /// Get the display name for a category by its int ID.
  static String getNameFromInt(int categoryId) {
    return getName(categoryId.toString());
  }

  /// Get the color associated with a category.
  static Color getColor(String categoryId) {
    return _categories[categoryId]?.color ?? _defaultCategory.color;
  }

  /// Get the color from int category ID.
  static Color getColorFromInt(int categoryId) {
    return getColor(categoryId.toString());
  }

  /// Get the icon for a category.
  static IconData getIcon(String categoryId) {
    return _categories[categoryId]?.icon ?? _defaultCategory.icon;
  }

  /// Get the icon from int category ID.
  static IconData getIconFromInt(int categoryId) {
    return getIcon(categoryId.toString());
  }

  /// Get all categories as a list of [CategoryFilterItem].
  static List<CategoryFilterItem> get allCategories {
    return _categories.entries.map((entry) {
      return CategoryFilterItem(
        id: entry.key,
        name: entry.value.name,
      );
    }).toList();
  }

  /// Check if a category ID is valid/known.
  static bool isValid(String categoryId) {
    return _categories.containsKey(categoryId);
  }

  /// Get the list of category IDs.
  static List<String> get allIds => _categories.keys.toList();
}

/// Data class for a single category's display info.
class _CategoryInfo {
  final String name;
  final Color color;
  final IconData icon;

  const _CategoryInfo(this.name, this.color, this.icon);
}

/// Data class for category filter items (used in filter widgets).
class CategoryFilterItem {
  final String id;
  final String name;

  const CategoryFilterItem({required this.id, required this.name});
}