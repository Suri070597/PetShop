import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/di/dependency_injection.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/datasources/drift/app_database.dart';

final categoryProductsProvider =
    StreamProvider.autoDispose.family<List<Product>, int>((ref, categoryId) {
  return ref.watch(catalogRepositoryProvider).watchProductsByCategory(categoryId);
});

class CategoryProductsScreen extends ConsumerWidget {
  const CategoryProductsScreen({
    super.key,
    required this.category,
  });

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

class _ProductGridCard extends StatelessWidget {
  const _ProductGridCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final price = product.discountPrice ?? product.price;

    return Container(
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: product.thumbnail == null
                  ? const ColoredBox(color: AppColors.mist)
                  : Image.network(
                      product.thumbnail!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const ColoredBox(color: AppColors.mist),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            product.productName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              height: 1.12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  MoneyFormatter.usd(price),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.forest,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Icon(
                Icons.add_circle,
                color: AppColors.forest,
                size: 28,
              ),
            ],
          ),
        ],
      ),
    );
  }
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
            Icon(
              Icons.inventory_2_outlined,
              size: 54,
              color: AppColors.forest,
            ),
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