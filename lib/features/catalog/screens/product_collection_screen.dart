import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/di/dependency_injection.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/datasources/drift/app_database.dart';

enum ProductCollectionType {
  hot,
  newest,
  bestSelling,
}

extension ProductCollectionTypeText on ProductCollectionType {
  String get title {
    switch (this) {
      case ProductCollectionType.hot:
        return 'Sản phẩm nổi bật';
      case ProductCollectionType.newest:
        return 'Sản phẩm mới';
      case ProductCollectionType.bestSelling:
        return 'Sản phẩm bán chạy';
    }
  }

  IconData get icon {
    switch (this) {
      case ProductCollectionType.hot:
        return Icons.local_fire_department_outlined;
      case ProductCollectionType.newest:
        return Icons.new_releases_outlined;
      case ProductCollectionType.bestSelling:
        return Icons.trending_up;
    }
  }
}

final productCollectionProvider = StreamProvider.autoDispose
    .family<List<Product>, ProductCollectionType>((ref, type) {
  final repository = ref.watch(catalogRepositoryProvider);

  switch (type) {
    case ProductCollectionType.hot:
      return repository.watchFeaturedProducts();
    case ProductCollectionType.newest:
      return repository.watchNewProducts();
    case ProductCollectionType.bestSelling:
      return repository.watchBestSellingProducts();
  }
});

class ProductCollectionScreen extends ConsumerWidget {
  const ProductCollectionScreen({
    super.key,
    required this.type,
  });

  final ProductCollectionType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productCollectionProvider(type));

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(type.title),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: products.when(
        data: (items) {
          if (items.isEmpty) {
            return _EmptyCollectionView(type: type);
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              return _ProductListTile(product: items[index]);
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

class _ProductListTile extends StatelessWidget {
  const _ProductListTile({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final price = product.discountPrice ?? product.price;

    return Container(
      height: 138,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: 112,
              height: 112,
              child: product.thumbnail == null
                  ? const ColoredBox(color: AppColors.mist)
                  : Image.network(
                      product.thumbnail!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const ColoredBox(color: AppColors.mist),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 18,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.brand ?? 'PetJoy',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        MoneyFormatter.usd(price),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.forest,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.star,
                      color: AppColors.honey,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      product.averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCollectionView extends StatelessWidget {
  const _EmptyCollectionView({required this.type});

  final ProductCollectionType type;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(type.icon, size: 54, color: AppColors.forest),
            const SizedBox(height: 16),
            Text(
              'Chưa có sản phẩm',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${type.title} hiện chưa có dữ liệu.',
              textAlign: TextAlign.center,
              style: const TextStyle(
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