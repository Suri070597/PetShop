import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';

/// Sort options for product list.
enum ProductSortOption {
  nameAsc('Tên A-Z', 'name_asc'),
  nameDesc('Tên Z-A', 'name_desc'),
  priceAsc('Giá tăng dần', 'price_asc'),
  priceDesc('Giá giảm dần', 'price_desc'),
  ratingDesc('Đánh giá cao nhất', 'rating_desc'),
  ratingAsc('Đánh giá thấp nhất', 'rating_asc');

  final String label;
  final String value;
  const ProductSortOption(this.label, this.value);
}

/// Sort dropdown widget for product list.
class ProductSortWidget extends StatelessWidget {
  const ProductSortWidget({
    super.key,
    required this.currentSort,
    this.onSortChanged,
  });

  final ProductSortOption currentSort;
  final ValueChanged<ProductSortOption?>? onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(21),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ProductSortOption>(
          value: currentSort,
          isDense: true,
          icon: const Icon(
            Icons.swap_vert,
            size: 20,
            color: AppColors.forest,
          ),
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          items: ProductSortOption.values.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option.label),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) onSortChanged?.call(value);
          },
        ),
      ),
    );
  }
}