import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/utils/category_helper.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../domain/product_model.dart';

/// Reusable product card widget for grid/list display.
class ProductCard extends ConsumerWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.showAddToCart = true,
  });

  final Product product;
  final VoidCallback? onTap;
  final bool showAddToCart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryLabel = CategoryHelper.getName(product.category);
    final categoryColor = CategoryHelper.getColor(product.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: product.image.isEmpty
                    ? Container(
                        color: AppColors.mist,
                        child: const Center(
                          child: Icon(
                            Icons.pets,
                            size: 48,
                            color: AppColors.muted,
                          ),
                        ),
                      )
                    : Image.network(
                        product.image,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, _, _) => Container(
                          color: AppColors.mist,
                          child: const Center(
                            child: Icon(
                              Icons.pets,
                              size: 48,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            // Category label - using CategoryHelper for dynamic lookup
            Text(
              categoryLabel,
              style: TextStyle(
                color: categoryColor,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            // Product name
            SizedBox(
              height: 44,
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Price & rating row
            Row(
              children: [
                // Rating badge
                if (product.rating > 0) ...[
                  const Icon(Icons.star, size: 16, color: AppColors.honey),
                  const SizedBox(width: 4),
                  Text(
                    product.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                const Spacer(),
                // Price
                Text(
                  MoneyFormatter.usd(product.price),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
            if (showAddToCart) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: () => _addToCart(context, ref),
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: const Text('Thêm', style: TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forest,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _addToCart(BuildContext context, WidgetRef ref) {
    ref.read(cartControllerProvider).addToCart(
      productId: product.id,
      productName: product.name,
      unitPrice: product.price,
      imageUrl: product.image,
      quantity: 1,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm "${product.name}" vào giỏ hàng'),
        action: SnackBarAction(
          label: 'Xem giỏ',
          textColor: AppColors.honey,
          onPressed: () =>
              Navigator.pushNamed(context, RouteNames.cart),
        ),
      ),
    );
  }
}