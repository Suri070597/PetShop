import 'package:drift/drift.dart';
import '../../features/products/domain/product_model.dart';
import '../datasources/drift/app_database.dart' as drift_db;

class WishlistRepository {
  final drift_db.AppDatabase _database;

  WishlistRepository(this._database);

  /// Watch the user's wishlist products.
  Stream<List<Product>> watchWishlist(String userId) {
    final query = _database.select(_database.wishlist).join([
      innerJoin(
        _database.products,
        _database.products.productId.equalsExp(_database.wishlist.productId),
      )
    ])..where(_database.wishlist.userId.equals(userId));

    return query.watch().map((rows) {
      return rows.map((row) {
        final p = row.readTable(_database.products);
        return Product(
          id: p.productId,
          name: p.productName,
          description: p.description,
          price: p.price,
          image: p.thumbnail ?? '',
          category: p.categoryId.toString(),
          rating: p.averageRating,
          categoryId: p.categoryId,
          stockQuantity: p.stockQuantity,
        );
      }).toList();
    });
  }

  /// Check if a product is in the user's wishlist.
  Future<bool> isFavorite(String userId, int productId) async {
    final row = await (_database.select(_database.wishlist)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.productId.equals(productId)))
        .getSingleOrNull();
    return row != null;
  }

  /// Toggle favorite status of a product for a user.
  Future<void> toggleFavorite(String userId, int productId) async {
    final row = await (_database.select(_database.wishlist)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.productId.equals(productId)))
        .getSingleOrNull();

    if (row != null) {
      // Remove
      await (_database.delete(_database.wishlist)
            ..where((t) => t.wishlistId.equals(row.wishlistId)))
          .go();
    } else {
      // Add
      await _database.into(_database.wishlist).insert(
            drift_db.WishlistCompanion.insert(
              userId: userId,
              productId: productId,
            ),
          );
    }
  }
}
