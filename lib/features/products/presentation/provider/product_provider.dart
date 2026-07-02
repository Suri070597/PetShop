import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../data/product_repository_impl.dart';
import '../../domain/product_model.dart';

/// Provider that exposes the [ProductNotifier] with full CRUD.
final productProvider =
    StateNotifierProvider<ProductNotifier, AsyncValue<List<Product>>>((ref) {
  final repository = ref.watch(productRepositoryImplProvider);
  return ProductNotifier(repository);
});

/// [ProductNotifier] manages the list of products via [ProductRepositoryImpl].
class ProductNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final ProductRepositoryImpl _repository;

  ProductNotifier(this._repository) : super(const AsyncLoading());

  /// Loads all products from Drift.
  Future<void> loadAll() async {
    state = const AsyncLoading();
    try {
      final products = await _repository.getAll();
      state = AsyncData(products);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Returns a single product by [id].
  Future<Product?> getById(String id) async {
    final current = state.valueOrNull;
    if (current != null) {
      final found = current.where((p) => p.id.toString() == id).firstOrNull;
      if (found != null) return found;
    }
    try {
      return await _repository.getById(id);
    } catch (_) {
      return null;
    }
  }

  /// Creates a new product with the given fields.
  Future<bool> create({
    required int id,
    required String name,
    required String description,
    required double price,
    required String image,
    required String category,
    required double rating,
    required int categoryId,
  }) async {
    try {
      final product = Product(
        id: id,
        name: name,
        description: description,
        price: price,
        image: image,
        category: category,
        rating: rating, 
        categoryId: categoryId,
      );
      await _repository.create(product);
      await loadAll();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Updates an existing [product].
  Future<bool> update(Product product) async {
    try {
      await _repository.update(product);
      await loadAll();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Deletes a product by its [id].
  Future<bool> delete(String id) async {
    try {
      await _repository.delete(id);
      await loadAll();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}