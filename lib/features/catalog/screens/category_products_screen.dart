import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/colors.dart';
import '../../../core/di/dependency_injection.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/datasources/drift/app_database.dart';
import '../../wishlist/presentation/controllers/wishlist_controller.dart';

final categoryProductsProvider = StreamProvider.autoDispose
    .family<List<Product>, int>((ref, categoryId) {
      return ref
          .watch(catalogRepositoryProvider)
          .watchProductsByCategory(categoryId);
    });

class CategoryProductsScreen extends ConsumerWidget {
  const CategoryProductsScreen({super.key, required this.category});

  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(categoryProductsProvider(category.categoryId));

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(category.categoryName),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: products.when(
        data: (items) {
          if (items.isEmpty) {
            return const _EmptyProductView();
          }

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.68,
            ),
            itemBuilder: (context, index) {
              return _ProductGridCard(product: items[index]);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.forest),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductGridCard extends ConsumerWidget {
  const _ProductGridCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final price = product.discountPrice ?? product.price;
    final isFavorite =
        ref.watch(isProductFavoriteProvider(product.productId)).valueOrNull ??
        false;
    final isInStock = product.stockQuantity > 0;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          RouteNames.productDetail,
          arguments: product.productId,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child:
                        product.thumbnail == null || product.thumbnail!.isEmpty
                        ? const ColoredBox(color: AppColors.mist)
                        : Image.network(
                            product.thumbnail!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const ColoredBox(color: AppColors.mist),
                          ),
                  ),
                  if (!isInStock)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
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
                    ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () {
                        ref
                            .read(wishlistControllerProvider)
                            .toggleFavorite(context, product.productId);
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite
                              ? AppColors.danger
                              : AppColors.muted,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  product.averageRating > 0
                      ? '${product.averageRating.toStringAsFixed(1)} (${product.reviewCount})'
                      : '0.0 (0)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: product.averageRating > 0
                        ? AppColors.ink
                        : AppColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              product.productName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 15,
                height: 1.12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    MoneyFormatter.vndFromLegacy(price),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.forest,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  isInStock ? 'Còn ${product.stockQuantity}' : 'Hết hàng',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isInStock ? AppColors.forest : AppColors.danger,
                  ),
                ),
                const SizedBox(width: 4),
                // IconButton(
                //   onPressed: isInStock ? () => _addToCart(context, ref, price) : null,
                //   icon: Icon(
                //     isInStock ? Icons.add_circle : Icons.remove_circle_outline,
                //     color: isInStock ? AppColors.forest : AppColors.muted,
                //     size: 28,
                //   ),
                //   tooltip: isInStock ? 'Thêm vào giỏ' : 'Hết hàng',
                //   padding: EdgeInsets.zero,
                //   constraints: const BoxConstraints(),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // void _addToCart(BuildContext context, WidgetRef ref, double price) {
  //   ref.read(cartControllerProvider).addToCart(
  //     productId: product.productId,
  //     productName: product.productName,
  //     unitPrice: price,
  //     imageUrl: product.thumbnail ?? '',
  //     quantity: 1,
  //   );
  //   if (!context.mounted) return;
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text('Đã thêm "${product.productName}" vào giỏ hàng'),
  //       action: SnackBarAction(
  //         label: 'Xem giỏ',
  //         textColor: AppColors.honey,
  //         onPressed: () => Navigator.pushNamed(context, RouteNames.cart),
  //       ),
  //     ),
  //   );
  // }
}

class _EmptyProductView extends StatelessWidget {
  const _EmptyProductView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 54, color: AppColors.forest),
            SizedBox(height: 16),
            Text(
              'Chưa có sản phẩm',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Danh mục này hiện chưa có sản phẩm để hiển thị.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 16,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
