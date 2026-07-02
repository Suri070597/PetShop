import 'package:drift/drift.dart';

import '../../../data/datasources/drift/app_database.dart' as drift_db;
import '../domain/cart_item_model.dart';

/// Drift-backed cart repository.
class CartRepository {
  final drift_db.AppDatabase _db;

  CartRepository(this._db);

  /// Returns all cart items for a given [userId].
  Future<List<CartItem>> getCartItems(String userId) async {
    final items = await (_db.select(_db.cartItems)
      ..where((t) => t.userId.equals(userId)))
        .get();
    return items.map(_toDomain).toList();
  }

  /// Adds a product to the cart, or increases quantity if already present.
  Future<void> addToCart({
    required String userId,
    required int productId,
    required double unitPrice,
    int quantity = 1,
  }) async {
    final existing = await (_db.select(_db.cartItems)
      ..where((t) =>
          t.userId.equals(userId) & t.productId.equals(productId)))
        .getSingleOrNull();

    if (existing != null) {
      // Increase quantity.
      await (_db.update(_db.cartItems)
        ..where((t) => t.cartItemId.equals(existing.cartItemId)))
          .write(drift_db.CartItemsCompanion(
        quantity: Value(existing.quantity + quantity),
      ));
    } else {
      // Insert new row.
      await _db.into(_db.cartItems).insertOnConflictUpdate(drift_db.CartItemsCompanion(
        userId: Value(userId),
        productId: Value(productId),
        quantity: Value(quantity),
        unitPrice: Value(unitPrice),
      ));
    }
  }

  /// Updates the [quantity] of a cart item.
  Future<void> updateQuantity(int cartItemId, int quantity) async {
    await (_db.update(_db.cartItems)
      ..where((t) => t.cartItemId.equals(cartItemId)))
        .write(drift_db.CartItemsCompanion(quantity: Value(quantity)));
  }

  /// Removes a cart item by its [cartItemId].
  Future<void> removeFromCart(int cartItemId) async {
    await (_db.delete(_db.cartItems)
      ..where((t) => t.cartItemId.equals(cartItemId)))
        .go();
  }

  /// Clears all items in the cart for a given [userId].
  Future<void> clearCart(String userId) async {
    await (_db.delete(_db.cartItems)
      ..where((t) => t.userId.equals(userId)))
        .go();
  }

  /// Converts a Drift [drift_db.CartItem] to a domain [CartItem].
  CartItem _toDomain(drift_db.CartItem item) {
    return CartItem(
      cartItemId: item.cartItemId,
      userId: item.userId,
      productId: item.productId,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
    );
  }
}