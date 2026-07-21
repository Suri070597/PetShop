import 'dart:async';

import 'package:drift/drift.dart';

import '../../../data/datasources/drift/app_database.dart' as drift_db;
import '../domain/product_model.dart';
import '../domain/product_repository.dart';

/// Drift-backed implementation of [ProductRepository].
class ProductRepositoryImpl implements ProductRepository {
  final drift_db.AppDatabase _db;

  ProductRepositoryImpl(this._db);

  @override
  Future<List<Product>> getAll() async {
    final driftProducts = await _db.select(_db.products).get();
    return driftProducts.map(_toDomain).toList();
  }

  @override
  Future<Product?> getById(String id) async {
    final parsedId = int.tryParse(id);
    if (parsedId == null) return null;
    final driftProduct = await (_db.select(_db.products)
      ..where((t) => t.productId.equals(parsedId)))
        .getSingleOrNull();
    return driftProduct != null ? _toDomain(driftProduct) : null;
  }

  @override
  Future<void> create(Product product) async {
    await _db.into(_db.products).insertOnConflictUpdate(drift_db.ProductsCompanion(
      productId: Value(product.id),
      categoryId: const Value(1),
      productName: Value(product.name),
      description: Value(product.description),
      price: Value(product.price),
      stockQuantity: Value(product.stockQuantity.clamp(0, 5000)),
      thumbnail: Value(product.image),
      averageRating: Value(product.rating),
    ));
  }

  @override
  Future<void> update(Product product) async {
    await (_db.update(_db.products)
      ..where((t) => t.productId.equals(product.id)))
        .write(drift_db.ProductsCompanion(
      productName: Value(product.name),
      description: Value(product.description),
      price: Value(product.price),
      stockQuantity: Value(product.stockQuantity.clamp(0, 5000)),
      thumbnail: Value(product.image),
      averageRating: Value(product.rating),
    ));
  }

  @override
  Future<void> delete(String id) async {
    final parsedId = int.tryParse(id);
    if (parsedId == null) return;
    await (_db.delete(_db.products)
      ..where((t) => t.productId.equals(parsedId)))
        .go();
  }

  @override
  Future<List<Product>> search(String query) async {
    final lower = query.toLowerCase();
    final driftProducts = await (_db.select(_db.products)
      ..where((t) => t.productName.like('%$lower%')))
        .get();
    return driftProducts.map(_toDomain).toList();
  }

  @override
  Future<List<Product>> filter(
      bool Function(Product) predicate) async {
    final all = await _db.select(_db.products).get();
    return all.map(_toDomain).where(predicate).toList();
  }

  @override
  Future<List<Product>> sort(
      Comparator<Product> comparator) async {
    final all = await _db.select(_db.products).get();
    final result = all.map(_toDomain).toList();
    result.sort(comparator);
    return result;
  }

  /// Maps a Drift [drift_db.Product] -> domain [Product].
  Product _toDomain(drift_db.Product p) {
    return Product(
      id: p.productId,
      name: p.productName,
      description: p.description,
      price: p.price,
      image: p.thumbnail ?? '',
      category: p.categoryId.toString(),
      rating: p.averageRating,
      categoryId: p.categoryId,
      stockQuantity: p.stockQuantity.clamp(0, 5000),
    );
  }
}