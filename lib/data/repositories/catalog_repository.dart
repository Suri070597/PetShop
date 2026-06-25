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
}
