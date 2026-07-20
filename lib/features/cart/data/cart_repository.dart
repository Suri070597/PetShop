import 'package:drift/drift.dart';

import '../../../data/datasources/drift/app_database.dart' as drift_db;
import '../domain/cart_item_model.dart';

/// Drift-backed cart repository.
class CartRepository {
  final drift_db.AppDatabase _db;

  CartRepository(this._db);

  /// Đảm bảo user test `guest` tồn tại để các khóa ngoại Cart/Order hợp lệ.
  Future<void> _ensureUserExists(String userId) async {
    final existing = await _db.findUserById(userId);
    if (existing != null) {
      return;
    }

    await _db.into(_db.localUsers).insert(
      drift_db.LocalUsersCompanion(
        id: Value(userId),
        fullName: const Value('Khách hàng PetJoy'),
        email: Value('$userId@petjoy.local'),
        authProvider: const Value('local'),
        emailVerified: const Value(true),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  /// Returns all cart items for a given [userId].
  Future<List<CartItem>> getCartItems(String userId) async {
    await _ensureUserExists(userId);
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
    await _ensureUserExists(userId);

    final product = await (_db.select(_db.products)
      ..where((t) => t.productId.equals(productId)))
        .getSingleOrNull();
    if (product == null || !product.status) {
      throw StateError('Sản phẩm không còn được bán.');
    }

    final existing = await (_db.select(_db.cartItems)
      ..where(
            (t) => t.userId.equals(userId) & t.productId.equals(productId),
      ))
        .getSingleOrNull();

    final newQuantity = (existing?.quantity ?? 0) + quantity;
    if (newQuantity > product.stockQuantity) {
      throw StateError(
        '${product.productName} chỉ còn ${product.stockQuantity} sản phẩm.',
      );
    }

    if (existing != null) {
      await (_db.update(_db.cartItems)
        ..where((t) => t.cartItemId.equals(existing.cartItemId)))
          .write(
        drift_db.CartItemsCompanion(
          quantity: Value(newQuantity),
          unitPrice: Value(unitPrice),
        ),
      );
    } else {
      await _db.into(_db.cartItems).insert(
        drift_db.CartItemsCompanion.insert(
          userId: userId,
          productId: productId,
          quantity: Value(quantity),
          unitPrice: unitPrice,
        ),
      );
    }
  }

  /// Updates the [quantity] of a cart item and validates stock.
  Future<void> updateQuantity(int cartItemId, int quantity) async {
    final cartItem = await (_db.select(_db.cartItems)
      ..where((t) => t.cartItemId.equals(cartItemId)))
        .getSingleOrNull();
    if (cartItem == null) {
      throw StateError('Không tìm thấy sản phẩm trong giỏ.');
    }

    final product = await (_db.select(_db.products)
      ..where((t) => t.productId.equals(cartItem.productId)))
        .getSingleOrNull();
    if (product == null || !product.status) {
      throw StateError('Sản phẩm không còn được bán.');
    }
    if (quantity > product.stockQuantity) {
      throw StateError(
        '${product.productName} chỉ còn ${product.stockQuantity} sản phẩm.',
      );
    }

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
