import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../shared/utils/category_helper.dart';
import '../../domain/product_model.dart';
import '../widgets/filter_widget.dart';
import '../widgets/product_card.dart';
import '../widgets/search_bar.dart';
import '../widgets/sort_widget.dart';

/// Provider that loads all products and exposes them as a stream.
final allProductsProvider = FutureProvider<List<Product>>((ref) async {
  final repo = ref.read(productRepositoryImplProvider);
  return repo.getAll();
});

/// Product list screen with search, filter, and sort.
class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key, this.initialCategory});

  final String? initialCategory;

  static const routeName = '/san-pham';

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  ProductSortOption _currentSort = ProductSortOption.nameAsc;
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];

  // Categories loaded dynamically from CategoryHelper
  List<CategoryFilterItem> get _categories => CategoryHelper.allCategories;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() => _searchQuery = _searchController.text);
    _applyFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        // Search filter
        if (_searchQuery.isNotEmpty &&
            !product.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return false;
        }
        // Category filter
        if (_selectedCategory != null &&
            product.category != _selectedCategory) {
          return false;
        }
        return true;
      }).toList();
      // Apply sort
      _sortProducts();
    });
  }

  void _sortProducts() {
    switch (_currentSort) {
      case ProductSortOption.nameAsc:
        _filteredProducts.sort((a, b) => a.name.compareTo(b.name));
      case ProductSortOption.nameDesc:
        _filteredProducts.sort((a, b) => b.name.compareTo(a.name));
      case ProductSortOption.priceAsc:
        _filteredProducts.sort((a, b) => a.price.compareTo(b.price));
      case ProductSortOption.priceDesc:
        _filteredProducts.sort((a, b) => b.price.compareTo(a.price));
      case ProductSortOption.ratingDesc:
        _filteredProducts.sort((a, b) => b.rating.compareTo(a.rating));
      case ProductSortOption.ratingAsc:
        _filteredProducts.sort((a, b) => a.rating.compareTo(b.rating));
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Sản phẩm'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
            child: Column(
              children: [
                // Search bar
                ProductSearchBar(
                  controller: _searchController,
                  hintText: 'Tìm sản phẩm...',
                ),
                const SizedBox(height: 10),
                // Filter & Sort row
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: ProductFilterWidget(
                          categories: _categories,
                          selectedCategory: _selectedCategory,
                          onCategorySelected: (category) {
                            setState(() => _selectedCategory = category);
                            _applyFilters();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ProductSortWidget(
                      currentSort: _currentSort,
                      onSortChanged: (option) {
                        if (option != null) {
                          setState(() => _currentSort = option);
                          _applyFilters();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
              const SizedBox(height: 16),
              const Text('Không thể tải sản phẩm',
                  style: AppTextStyles.body),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(allProductsProvider),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (products) {
          // Initialize all products when data arrives
          if (_allProducts.isEmpty) {
            _allProducts = products;
            _applyFilters();
          }

          if (_filteredProducts.isEmpty) {
            if (_searchQuery.isNotEmpty || _selectedCategory != null) {
              return _buildNoResults();
            }
            return _buildEmptyProducts();
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allProductsProvider);
              _allProducts = [];
              _filteredProducts = [];
            },
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 90),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.62,
              ),
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                return ProductCard(
                  product: product,
                  showAddToCart: true,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      RouteNames.productDetail,
                      arguments: product.id,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: AppColors.muted.withValues(alpha: 0.5)),
            const SizedBox(height: 20),
            const Text(
              'Không tìm thấy sản phẩm',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Không có sản phẩm nào cho "$_searchQuery"'
                  : 'Không có sản phẩm trong danh mục này',
              style: const TextStyle(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _selectedCategory = null;
                  _searchQuery = '';
                });
                _applyFilters();
              },
              child: const Text('Xóa bộ lọc'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyProducts() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: AppColors.muted.withValues(alpha: 0.5)),
            const SizedBox(height: 20),
            const Text(
              'Chưa có sản phẩm',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}