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
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    product.image.isEmpty
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
                    if (!product.isInStock)
                      Container(
                        color: Colors.white.withValues(alpha: 0.6),
                        child: const Center(
                          child: Text(
                            'Hết hàng',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.danger,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Category label & Rating badge
            Row(
              children: [
                Text(
                  categoryLabel,
                  style: TextStyle(
                    color: categoryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 15, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(
                      product.rating > 0 ? product.rating.toStringAsFixed(1) : '0.0',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: product.rating > 0 ? AppColors.ink : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Product name
            SizedBox(
              height: 40,
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Price & Status row
            Row(
              children: [
                Text(
                  MoneyFormatter.usd(product.price),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const Spacer(),
                Text(
                  product.isInStock ? 'Còn hàng' : 'Hết hàng',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: product.isInStock ? AppColors.forest : AppColors.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            // Stock badge
            _StockBadge(stockQuantity: product.stockQuantity),
            if (showAddToCart) ...[
              const SizedBox(height: 7),
              SizedBox(
                width: double.infinity,
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: product.isInStock
                      ? () => _addToCart(context, ref)
                      : null,
                  icon: Icon(
                    product.isInStock
                        ? Icons.add_shopping_cart
                        : Icons.remove_shopping_cart_outlined,
                    size: 18,
                  ),
                  label: Text(
                    product.isInStock ? 'Thêm' : 'Hết hàng',
                    style: const TextStyle(fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: product.isInStock
                        ? AppColors.forest
                        : AppColors.muted,
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
    if (!context.mounted) return;
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

/// Badge hiển thị tình trạng tồn kho.
class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.stockQuantity});

  final int stockQuantity;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color textColor;
    final String label;
    final IconData icon;

    if (stockQuantity <= 0) {
      bgColor = AppColors.danger.withValues(alpha: 0.12);
      textColor = AppColors.danger;
      label = 'Hết hàng';
      icon = Icons.inventory_2_outlined;
    } else if (stockQuantity <= 10) {
      bgColor = const Color(0xFFFF9800).withValues(alpha: 0.13);
      textColor = const Color(0xFFE65100);
      label = 'Sắp hết ($stockQuantity)';
      icon = Icons.warning_amber_rounded;
    } else {
      bgColor = AppColors.leaf.withValues(alpha: 0.15);
      textColor = AppColors.forest;
      label = 'Còn $stockQuantity sp';
      icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}