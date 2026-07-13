import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../shared/utils/category_helper.dart';

/// Category filter chips for product list.
class ProductFilterWidget extends StatelessWidget {
  const ProductFilterWidget({
    super.key,
    required this.categories,
    required this.selectedCategory,
    this.onCategorySelected,
  });

  /// Available categories (list of (id, name)).
  final List<CategoryFilterItem> categories;

  /// Currently selected category id (null = all).
  final String? selectedCategory;

  /// Callback when a category is selected (null = all).
  final ValueChanged<String?>? onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1, // +1 for "All"
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            // "All" chip
            return _FilterChip(
              label: 'Tất cả',
              isSelected: selectedCategory == null,
              onTap: () => onCategorySelected?.call(null),
            );
          }
          final category = categories[index - 1];
          return _FilterChip(
            label: category.name,
            isSelected: selectedCategory == category.id,
            onTap: () => onCategorySelected?.call(category.id),
          );
        },
      ),
    );
  }
}

/// A single filter chip widget.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.forest : AppColors.mist,
          borderRadius: BorderRadius.circular(21),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.muted,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

