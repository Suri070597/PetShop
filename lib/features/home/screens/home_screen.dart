import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/constants/cloudinary_constants.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/di/dependency_injection.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/datasources/drift/app_database.dart';

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
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesStreamProvider);
    final products = ref.watch(featuredProductsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
              sliver: SliverList.list(
                children: [
                  const _HomeHeader(),
                  const SizedBox(height: 28),
                  const _SearchBar(),
                  const SizedBox(height: 26),
                  const _HeroBanner(),
                  const SizedBox(height: 32),
                  _SectionHeader(
                    title: 'Danh mục',
                    actionLabel: 'Xem tất cả',
                    onAction: () => setState(() => _selectedIndex = 1),
                  ),
                  const SizedBox(height: 18),
                  categories.when(
                    data: (items) => _CategoryScroller(categories: items),
                    loading: () => const _Skeleton(height: 104),
                    error: (error, _) =>
                        _InlineError(message: error.toString()),
                  ),
                  const SizedBox(height: 34),
                  const _SectionHeader(title: 'Nổi bật'),
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
                    (context, index) => _ProductCard(product: items[index]),
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
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () {},
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
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.mist,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.line),
          ),
          child: const Icon(
            Icons.receipt_long_outlined,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Icon(Icons.pets, color: AppColors.forest, size: 30),
        ],
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
  const _CategoryScroller({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.restaurant,
      Icons.checkroom_outlined,
      Icons.sports_baseball,
      Icons.medical_services_outlined,
    ];
    final colors = [
      AppColors.forest,
      AppColors.coffee,
      const Color(0xFF875D4E),
      AppColors.forest,
    ];

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 22),
        itemBuilder: (context, index) {
          final category = categories[index];
          return SizedBox(
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
                  child: Icon(
                    icons[index % icons.length],
                    color: colors[index % colors.length],
                    size: 34,
                  ),
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
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: product.thumbnail == null
                      ? const ColoredBox(color: AppColors.mist)
                      : Image.network(
                          product.thumbnail!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const ColoredBox(color: AppColors.mist),
                        ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      product.productId.isEven
                          ? Icons.favorite_border
                          : Icons.favorite_outline,
                      color: product.productId.isEven
                          ? AppColors.danger
                          : AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            product.categoryId == 1 ? 'Thức ăn' : 'Đồ chơi',
            style: TextStyle(
              color: product.categoryId == 1
                  ? AppColors.forest
                  : const Color(0xFF875D4E),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 44,
            child: Text(
              product.productName,
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
          Row(
            children: [
              Expanded(
                child: Text(
                  MoneyFormatter.usd(product.discountPrice ?? product.price),
                  style: const TextStyle(
                    fontSize: 23,
                    color: AppColors.ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.forest,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.selectedIndex, required this.onTap});

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_outlined, 'Trang chủ'),
      (Icons.category_outlined, 'Danh mục'),
      (Icons.shopping_cart_outlined, 'Giỏ hàng'),
      (Icons.favorite_border, 'Yêu thích'),
      (Icons.person_outline, 'Hồ sơ'),
    ];

    return Container(
      height: 88,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(items.length, (index) {
          final isSelected = index == selectedIndex;
          final item = items[index];
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () => onTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 58,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.honey : Colors.transparent,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          item.$1,
                          color: isSelected
                              ? AppColors.coffee
                              : AppColors.muted,
                        ),
                        if (index == 2)
                          const Positioned(
                            right: -4,
                            top: -4,
                            child: SizedBox.square(
                              dimension: 8,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppColors.danger,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      item.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected ? AppColors.coffee : AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
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
