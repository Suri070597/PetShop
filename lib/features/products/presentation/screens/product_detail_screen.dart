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
import '../provider/product_provider.dart';

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
                        onTap: () => setState(() => _quantity++),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Đánh giá sản phẩm',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      if (ref.watch(currentUserIdProvider) != null)
                        TextButton.icon(
                          onPressed: () => _showWriteReviewSheet(context),
                          icon: const Icon(Icons.rate_review_outlined, size: 18, color: AppColors.forest),
                          label: const Text(
                            'Viết đánh giá',
                            style: TextStyle(color: AppColors.forest, fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
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
                                        Text(
                                          review.reviewerName,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.ink),
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
                    onPressed: () => _addToCart(product),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: Text(
                      'Thêm vào giỏ - \$${(product.price * _quantity).toStringAsFixed(2)}',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forest,
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
    ref.read(cartProvider.notifier).addToCart(
          productId: product.id,
          productName: product.name,
          unitPrice: product.price,
          imageUrl: product.image,
          quantity: _quantity,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm $_quantity x "${product.name}" vào giỏ hàng'),
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

  Future<void> _showWriteReviewSheet(BuildContext context) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng đăng nhập để viết đánh giá.'),
          action: SnackBarAction(
            label: 'Đăng nhập',
            textColor: AppColors.honey,
            onPressed: () => Navigator.pushNamed(context, RouteNames.login),
          ),
        ),
      );
      return;
    }

    final eligibility = await ref
        .read(reviewsRepositoryProvider)
        .checkReviewEligibility(userId, widget.productId);

    if (!context.mounted) return;

    if (eligibility.status == ReviewEligibilityStatus.notPurchased) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Chưa thể đánh giá'),
          content: const Text(
            'Bạn chỉ có thể viết đánh giá sau khi đã mua và nhận thành công sản phẩm này (Đơn hàng ở trạng thái Đã giao).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đã hiểu', style: TextStyle(color: AppColors.forest)),
            ),
          ],
        ),
      );
      return;
    }

    if (eligibility.status == ReviewEligibilityStatus.alreadyReviewedAllPurchases) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Đã đánh giá lượt mua này'),
          content: Text(
            'Bạn đã viết đánh giá cho tất cả (${eligibility.deliveredCount}) lượt mua sản phẩm này rồi. Cảm ơn bạn!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng', style: TextStyle(color: AppColors.forest)),
            ),
          ],
        ),
      );
      return;
    }

    int selectedRating = 5;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                22,
                22,
                22,
                MediaQuery.of(context).viewInsets.bottom + 34,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Viết đánh giá',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Đánh giá của bạn về sản phẩm này:',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(5, (index) {
                      final starRating = index + 1;
                      return GestureDetector(
                        onTap: () => setState(() => selectedRating = starRating),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Icon(
                            starRating <= selectedRating ? Icons.star : Icons.star_border,
                            color: AppColors.honey,
                            size: 38,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Nhận xét của bạn:',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: commentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Nhập bình luận tại đây...',
                      hintStyle: const TextStyle(color: AppColors.muted, fontSize: 15),
                      fillColor: AppColors.mist,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        final comment = commentController.text;
                        if (comment.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng nhập bình luận')),
                          );
                          return;
                        }
                        
                        final userId = ref.read(currentUserIdProvider);
                        if (userId == null) return;
                        
                        try {
                          await ref.read(reviewsRepositoryProvider).addReview(
                            userId: userId,
                            productId: widget.productId,
                            rating: selectedRating,
                            comment: comment,
                          );
                          
                          ref.invalidate(productReviewsStreamProvider(widget.productId));
                          ref.invalidate(productProvider);
                          
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã gửi đánh giá thành công!')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gửi đánh giá lỗi: ${e.toString()}')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.forest,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Gửi đánh giá',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Round quantity adjustment button.
class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.mist,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.ink, size: 22),
      ),
    );
  }
}