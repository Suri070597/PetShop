import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../products/domain/product_extension.dart'; // Đường dẫn tới file bạn vừa tạo ở Bước 1
import '../../../app/constants/cloudinary_constants.dart';
import '../../../app/router/route_names.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/di/dependency_injection.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/datasources/drift/app_database.dart';
import '../../../shared/utils/category_helper.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../catalog/screens/category_products_screen.dart';
import '../../catalog/screens/product_collection_screen.dart';
import '../../wishlist/presentation/controllers/wishlist_controller.dart';
import '../../notifications/presentation/controllers/notifications_controller.dart';
import '../widgets/home_drawer.dart';

final categoriesStreamProvider = StreamProvider.autoDispose<List<Category>>((
  ref,
) async* {
  await ref.watch(catalogRepositoryProvider).ensureSeeded();
  yield* ref.watch(catalogRepositoryProvider).watchCategories();
});

final featuredProductsStreamProvider =
    StreamProvider.autoDispose<List<Product>>((ref) async* {
      await ref.watch(catalogRepositoryProvider).ensureSeeded();
      yield* ref.watch(catalogRepositoryProvider).watchFeaturedProducts();
    });

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  void _onBottomNavTap(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesStreamProvider);
    final products = ref.watch(featuredProductsStreamProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFAFAFA),
      drawer: const HomeDrawer(),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
              sliver: SliverList.list(
                children: [
                  _HomeHeader(
                    onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  const SizedBox(height: 28),
                  _SearchBar(
                    onTap: () =>
                        Navigator.pushNamed(context, RouteNames.productList),
                  ),
                  const SizedBox(height: 26),
                  const _HeroBanner(),
                  const SizedBox(height: 32),
                  _SectionHeader(
                    title: 'Danh mục',
                    actionLabel: 'Xem tất cả',
                    onAction: () {
                      Navigator.pushNamed(context, RouteNames.productList);
                    },
                  ),
                  const SizedBox(height: 18),
                  categories.when(
                    data: (items) => _CategoryScroller(
                      categories: items,
                      onCategoryTap: (category) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CategoryProductsScreen(category: category),
                          ),
                        );
                      },
                    ),
                    loading: () => const _Skeleton(height: 104),
                    error: (error, _) =>
                        _InlineError(message: error.toString()),
                  ),
                  const SizedBox(height: 34),
                  _SectionHeader(
                    title: 'Nổi bật',
                    actionLabel: 'Xem tất cả',
                    onAction: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProductCollectionScreen(
                            type: ProductCollectionType.hot,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  _ProductCollectionShortcuts(
                    onSelected: (type) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductCollectionScreen(type: type),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
            products.when(
              data: (items) => SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 110),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                    childAspectRatio: 0.68,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ProductCard(
                      product: items[index],
                      onTap: () => Navigator.pushNamed(
                        context,
                        RouteNames.productDetail,
                        arguments: items[index].productId,
                      ),
                    ),
                    childCount: items.length,
                  ),
                ),
              ),
              loading: () => const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 22),
                sliver: SliverToBoxAdapter(child: _Skeleton(height: 260)),
              ),
              error: (error, _) => SliverToBoxAdapter(
                child: _InlineError(message: error.toString()),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: _selectedIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }
}

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader({required this.onMenuTap});

  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Row(
      children: [
        IconButton(
          onPressed: onMenuTap,
          icon: const Icon(Icons.menu, size: 30, color: AppColors.ink),
          tooltip: 'Mở menu',
        ),
        const Expanded(
          child: Text(
            'Pet Shop Hoàn Hảo',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.forest,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, RouteNames.notifications),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.mist,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.line),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.muted,
                  size: 26,
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: AppColors.mist,
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.search, color: AppColors.muted, size: 32),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'Tìm thức ăn, đồ chơi, phụ kiện...',
                style: TextStyle(color: Color(0xFF9AA19A), fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.pets, color: Color.fromARGB(255, 40, 95, 54), size: 30),
          ],
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 210,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              CloudinaryConstants.homeBannerUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const ColoredBox(color: AppColors.mist),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF9C26D).withValues(alpha: 0.74),
                    Colors.transparent,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.forest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Hàng mới',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chiều chuộng\nbé cưng',
                    style: TextStyle(
                      color: AppColors.forestDark,
                      fontSize: 28,
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Mua ngay',
                        style: TextStyle(
                          color: AppColors.forest,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: AppColors.forest),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCollectionShortcuts extends StatelessWidget {
  const _ProductCollectionShortcuts({required this.onSelected});

  final ValueChanged<ProductCollectionType> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = [
      _CollectionShortcut(
        label: 'Hot',
        icon: Icons.local_fire_department_outlined,
        type: ProductCollectionType.hot,
      ),
      _CollectionShortcut(
        label: 'Mới',
        icon: Icons.new_releases_outlined,
        type: ProductCollectionType.newest,
      ),
      _CollectionShortcut(
        label: 'Bán chạy',
        icon: Icons.trending_up,
        type: ProductCollectionType.bestSelling,
      ),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];

          return ActionChip(
            avatar: Icon(item.icon, size: 18, color: AppColors.forest),
            label: Text(item.label),
            labelStyle: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
            backgroundColor: Colors.white,
            side: const BorderSide(color: AppColors.line),
            onPressed: () => onSelected(item.type),
          );
        },
      ),
    );
  }
}

class _CollectionShortcut {
  const _CollectionShortcut({
    required this.label,
    required this.icon,
    required this.type,
  });

  final String label;
  final IconData icon;
  final ProductCollectionType type;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTextStyles.section)),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(color: AppColors.forest),
            ),
          ),
      ],
    );
  }
}

class _CategoryScroller extends StatelessWidget {
  const _CategoryScroller({
    required this.categories,
    required this.onCategoryTap,
  });

  final List<Category> categories;
  final ValueChanged<Category> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 22),
        itemBuilder: (context, index) {
          final category = categories[index];
          final categoryId = category.categoryId.toString();
          final icon = CategoryHelper.getIcon(categoryId);
          final color = CategoryHelper.getColor(categoryId);

          return GestureDetector(
            onTap: () => onCategoryTap(category),
            child: SizedBox(
              width: 86,
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppColors.mist,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(icon, color: color, size: 34),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    category.categoryName,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.product, this.onTap});

  final Product product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite =
        ref.watch(isProductFavoriteProvider(product.productId)).valueOrNull ??
        false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 255, 255),
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
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: product.thumbnail == null
                        ? const ColoredBox(
                            color: Color.fromARGB(255, 95, 76, 76),
                          )
                        : Image.network(
                            product.thumbnail!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const ColoredBox(
                              color: Color.fromARGB(255, 96, 148, 70),
                            ),
                          ),
                  ),
                  if (product.stockQuantity <= 0)
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
                          color: Color.fromARGB(255, 255, 255, 255),
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
            // Category label & Rating badge
            Row(
              children: [
                Text(
                  product.categoryName,
                  style: TextStyle(
                    color: product.categoryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 15,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      product.averageRating > 0
                          ? product.averageRating.toStringAsFixed(1)
                          : '0.0',
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
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 40,
              child: Text(
                product.productName,
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    MoneyFormatter.vndFromLegacy(
                      product.discountPrice ?? product.price,
                    ),
                    style: const TextStyle(
                      fontSize: 17,
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  product.stockQuantity > 0
                      ? 'Còn ${product.stockQuantity}'
                      : 'Hết hàng',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: product.stockQuantity > 0
                        ? AppColors.forest
                        : AppColors.danger,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(message, style: const TextStyle(color: AppColors.danger)),
    );
  }
}
