import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/colors.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../products/presentation/widgets/product_card.dart';
import '../controllers/wishlist_controller.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  static const routeName = RouteNames.wishlist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Yêu thích'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
      ),
      body: userId == null
          ? const _GuestWishlistContent()
          : const _SignedInWishlistContent(),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 3),
    );
  }
}

class _SignedInWishlistContent extends ConsumerWidget {
  const _SignedInWishlistContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(wishlistStreamProvider);

    return wishlistAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.forest)),
      error: (error, _) => Center(
        child: Text('Đã xảy ra lỗi: ${error.toString()}', style: const TextStyle(color: AppColors.danger)),
      ),
      data: (products) {
        if (products.isEmpty) {
          return const _EmptyWishlistContent();
        }

        return GridView.builder(
          padding: const EdgeInsets.all(18),
          itemCount: products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.68,
          ),
          itemBuilder: (context, index) {
            final product = products[index];
            return Stack(
              children: [
                ProductCard(
                  product: product,
                  onTap: () => Navigator.pushNamed(
                    context,
                    RouteNames.productDetail,
                    arguments: product.id,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      ref.read(wishlistControllerProvider).toggleFavorite(product.id);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
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
                      child: const Icon(
                        Icons.favorite,
                        color: AppColors.danger,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _EmptyWishlistContent extends StatelessWidget {
  const _EmptyWishlistContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.mist,
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 60,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Danh sách trống',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Hãy thả tim những sản phẩm bạn yêu thích để lưu trữ tại đây nhé!',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.muted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(context, RouteNames.home),
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Mua sắm ngay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forest,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestWishlistContent extends StatelessWidget {
  const _GuestWishlistContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.mist,
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 60,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Bạn chưa đăng nhập',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Đăng nhập để xem danh sách sản phẩm yêu thích của bạn.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.muted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Đăng nhập',
              icon: Icons.login,
              onPressed: () => Navigator.pushReplacementNamed(context, RouteNames.login),
            ),
          ],
        ),
      ),
    );
  }
}
