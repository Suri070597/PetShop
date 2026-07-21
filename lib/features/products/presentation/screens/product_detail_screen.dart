import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/utils/category_helper.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../domain/product_model.dart';
import '../../../wishlist/presentation/controllers/wishlist_controller.dart';
import '../../../../data/repositories/reviews_repository.dart';


final productReviewsStreamProvider = StreamProvider.family.autoDispose<List<ReviewDisplay>, int>((ref, productId) {
  return ref.watch(reviewsRepositoryProvider).watchReviewsForProduct(productId);
});

/// Screen to view product details.
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final int productId;

  static const routeName = RouteNames.productDetail;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  Product? _product;
  bool _isLoading = true;
  String? _error;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(productRepositoryImplProvider);
      final product = await repo.getById(widget.productId.toString());
      setState(() {
        _product = product;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết sản phẩm')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Không tìm thấy sản phẩm',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProduct,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final product = _product!;
    final categoryLabel = _categoryName(product.category);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Chi tiết sản phẩm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Product image
          SliverToBoxAdapter(
            child: Container(
              height: 320,
              width: double.infinity,
              color: Colors.white,
              child: product.image.isEmpty
                  ? const Center(
                      child: Icon(Icons.pets, size: 80, color: AppColors.muted),
                    )
                  : Image.network(
                      product.image,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Center(
                        child:
                            Icon(Icons.pets, size: 80, color: AppColors.muted),
                      ),
                    ),
            ),
          ),

          // Product info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.forest.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      categoryLabel,
                      style: const TextStyle(
                        color: AppColors.forest,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Product name
                  Text(
                    product.name,
                    style: AppTextStyles.title,
                  ),
                  const SizedBox(height: 8),

                  // Rating & review count
                  ref.watch(productReviewsStreamProvider(widget.productId)).when(
                    data: (reviewsList) {
                      final count = reviewsList.length;
                      final totalRating = reviewsList.fold<int>(0, (sum, r) => sum + r.rating);
                      final average = count > 0 ? (totalRating / count) : product.rating;
                      return Row(
                        children: [
                          const Icon(Icons.star, color: AppColors.honey, size: 22),
                          const SizedBox(width: 6),
                          Text(
                            average.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '($count đánh giá)',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => Row(
                      children: [
                        const Icon(Icons.star, color: AppColors.honey, size: 22),
                        const SizedBox(width: 6),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
                        ),
                        const SizedBox(width: 8),
                        const Text('(Đang tải...)', style: TextStyle(color: AppColors.muted, fontSize: 14)),
                      ],
                    ),
                    error: (e, s) => Row(
                      children: [
                        const Icon(Icons.star, color: AppColors.honey, size: 22),
                        const SizedBox(width: 6),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
                        ),
                        const SizedBox(width: 8),
                        const Text('(Lỗi)', style: TextStyle(color: AppColors.muted, fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Price
                  Text(
                    MoneyFormatter.usd(product.price),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.forest,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Stock quantity badge
                  _StockStatusBadge(stockQuantity: product.stockQuantity),
                  const SizedBox(height: 22),

                  // Quantity selector
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Số lượng:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: 16),
                      _QuantityButton(
                        icon: Icons.remove,
                        enabled: _quantity > 1,
                        onTap: () {
                          if (_quantity > 1) {
                            setState(() => _quantity--);
                          }
                        },
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '$_quantity',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: 16),
                      _QuantityButton(
                        icon: Icons.add,
                        enabled: product.isInStock && _quantity < product.maxOrderQty,
                        onTap: () {
                          if (_quantity < product.maxOrderQty) {
                            setState(() => _quantity++);
                          }
                        },
                      ),
                      const Spacer(),
                      if (product.stockQuantity > 0)
                        Text(
                          'Tối đa: ${product.maxOrderQty}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'Mô tả sản phẩm',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    product.description,
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Reviews Header
                  const Text(
                    'Đánh giá sản phẩm',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Reviews List
                  ref.watch(productReviewsStreamProvider(widget.productId)).when(
                    data: (reviewsList) {
                      if (reviewsList.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Chưa có đánh giá nào cho sản phẩm này.',
                            style: TextStyle(color: AppColors.muted, fontSize: 14),
                          ),
                        );
                      }
                      
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reviewsList.length,
                        separatorBuilder: (context, index) => const Divider(height: 24),
                        itemBuilder: (context, index) {
                          final review = reviewsList[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppColors.mist,
                                    backgroundImage: review.avatarUrl != null ? NetworkImage(review.avatarUrl!) : null,
                                    child: review.avatarUrl == null ? const Icon(Icons.person, size: 18, color: AppColors.muted) : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                review.reviewerName,
                                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.ink),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.forest.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.verified, size: 12, color: AppColors.forest),
                                                  SizedBox(width: 3),
                                                  Text(
                                                    'Đã mua hàng',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.forest,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                                          style: const TextStyle(color: AppColors.muted, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: List.generate(5, (starIdx) {
                                      return Icon(
                                        starIdx < review.rating ? Icons.star : Icons.star_border,
                                        color: AppColors.honey,
                                        size: 16,
                                      );
                                    }),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                review.comment,
                                style: const TextStyle(color: AppColors.ink, fontSize: 14, height: 1.3),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(color: AppColors.forest),
                      ),
                    ),
                    error: (e, _) => Text(
                      'Lỗi tải đánh giá: ${e.toString()}',
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // Favorite button
              GestureDetector(
                onTap: () {
                  ref.read(wishlistControllerProvider).toggleFavorite(context, widget.productId);
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.mist,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    ref.watch(isProductFavoriteProvider(widget.productId)).valueOrNull ?? false
                        ? Icons.favorite
                        : Icons.favorite_outline,
                    color: ref.watch(isProductFavoriteProvider(widget.productId)).valueOrNull ?? false
                        ? AppColors.danger
                        : AppColors.muted,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Add to cart button
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: product.isInStock ? () => _addToCart(product) : null,
                    icon: Icon(
                      product.isInStock
                          ? Icons.add_shopping_cart
                          : Icons.remove_shopping_cart_outlined,
                    ),
                    label: Text(
                      product.isInStock
                          ? 'Thêm vào giỏ - \$${(product.price * _quantity).toStringAsFixed(2)}'
                          : 'Hết hàng',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: product.isInStock
                          ? AppColors.forest
                          : AppColors.muted,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addToCart(Product product) {
    // Ensure quantity is within stock limit before adding
    final safeQty = _quantity.clamp(1, product.maxOrderQty > 0 ? product.maxOrderQty : 1);
    ref.read(cartProvider.notifier).addToCart(
          productId: product.id,
          productName: product.name,
          unitPrice: product.price,
          imageUrl: product.image,
          quantity: safeQty,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm $safeQty x "${product.name}" vào giỏ hàng'),
        action: SnackBarAction(
          label: 'Xem giỏ',
          textColor: AppColors.honey,
          onPressed: () =>
              Navigator.pushReplacementNamed(context, RouteNames.cart),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static String _categoryName(String categoryId) {
    return CategoryHelper.getName(categoryId);
  }
}

/// Round quantity adjustment button.
class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled ? AppColors.mist : AppColors.mist.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: enabled ? AppColors.ink : AppColors.muted,
          size: 22,
        ),
      ),
    );
  }
}

/// Badge hiển thị tình trạng tồn kho chi tiết trong màn hình detail.
class _StockStatusBadge extends StatelessWidget {
  const _StockStatusBadge({required this.stockQuantity});

  final int stockQuantity;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color textColor;
    final String label;
    final IconData icon;

    if (stockQuantity <= 0) {
      bgColor = AppColors.danger.withValues(alpha: 0.10);
      textColor = AppColors.danger;
      label = 'Hết hàng';
      icon = Icons.inventory_2_outlined;
    } else if (stockQuantity <= 10) {
      bgColor = const Color(0xFFFF9800).withValues(alpha: 0.12);
      textColor = const Color(0xFFE65100);
      label = 'Sắp hết hàng — Còn $stockQuantity sản phẩm';
      icon = Icons.warning_amber_rounded;
    } else {
      bgColor = AppColors.leaf.withValues(alpha: 0.13);
      textColor = AppColors.forest;
      label = 'Còn hàng — $stockQuantity sản phẩm trong kho';
      icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}