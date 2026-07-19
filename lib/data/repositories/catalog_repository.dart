import 'package:drift/drift.dart';
import '../datasources/drift/app_database.dart';

class CatalogRepository {
  CatalogRepository(this._database);

  final AppDatabase _database;

  Future<void> ensureSeeded() => _database.seedCatalog();

  Stream<List<Category>> watchCategories() {
    return _database.select(_database.categories).watch();
  }

  Stream<List<Product>> watchFeaturedProducts() {
    final query = _database.select(_database.products)
      ..where((table) => table.isFeatured.equals(true))
      ..where((table) => table.status.equals(true));
    return query.watch();
  }

  Stream<List<Product>> watchProductsByCategory(int categoryId) {
    final query = _database.select(_database.products)
      ..where((table) => table.categoryId.equals(categoryId))
      ..where((table) => table.status.equals(true))
      ..orderBy([
        (table) =>
            OrderingTerm(expression: table.productName, mode: OrderingMode.asc),
      ]);

    return query.watch();
  }

  Stream<List<Product>> watchNewProducts() {
    final query = _database.select(_database.products)
      ..where((table) => table.status.equals(true))
      ..orderBy([
        (table) =>
            OrderingTerm(expression: table.createdAt, mode: OrderingMode.desc),
      ]);

    return query.watch();
  }

  Stream<List<Product>> watchBestSellingProducts() {
    final query = _database.select(_database.products)
      ..where((table) => table.status.equals(true))
      ..orderBy([
        (table) => OrderingTerm(
          expression: table.reviewCount,
          mode: OrderingMode.desc,
        ),
        (table) => OrderingTerm(
          expression: table.averageRating,
          mode: OrderingMode.desc,
        ),
      ]);

    return query.watch();
  }
}
