import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/cart_provider.dart';

/// Widget to display a single cart item with quantity controls.
class CartItemWidget extends StatelessWidget {
  const CartItemWidget({
    super.key,
    required this.item,
    this.onQuantityChanged,
    this.onRemove,
  });

  final CartItemDisplay item;
  final void Function(int newQuantity)? onQuantityChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 90,
              height: 90,
              color: AppColors.mist,
              child: item.imageUrl.isEmpty
                  ? const Icon(
                      Icons.pets,
                      size: 40,
                      color: AppColors.muted,
                    )
                  : Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.pets,
                        size: 40,
                        color: AppColors.muted,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),

          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),

                // Unit price
                Text(
                  MoneyFormatter.usd(item.unitPrice),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.forest,
                  ),
                ),
                const SizedBox(height: 10),

                // Quantity controls
                Row(
                  children: [
                    _QuantityControl(
                      icon: Icons.remove,
                      onTap: () {
                        if (item.quantity > 1) {
                          onQuantityChanged?.call(item.quantity - 1);
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _QuantityControl(
                      icon: Icons.add,
                      onTap: () =>
                          onQuantityChanged?.call(item.quantity + 1),
                    ),
                    const Spacer(),

                    // Total price
                    Text(
                      MoneyFormatter.usd(item.totalPrice),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.forest,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Delete button
          Column(
            children: [
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: AppColors.danger,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small round button for quantity adjustment.
class _QuantityControl extends StatelessWidget {
  const _QuantityControl({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.mist,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.ink, size: 18),
      ),
    );
  }
}