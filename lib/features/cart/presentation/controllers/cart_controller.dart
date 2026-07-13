import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cart_provider.dart';

/// Provider for cart controller that exposes actions.
final cartControllerProvider = Provider<CartController>((ref) {
  return CartController(ref);
});

/// Controller that provides cart actions to the UI.
class CartController {
  final Ref _ref;

  CartController(this._ref);

  /// Get the cart notifier.
  CartNotifier get _notifier => _ref.read(cartProvider.notifier);

  /// Load cart items.
  Future<void> loadCart() => _notifier.loadCart();

  /// Add a product to cart.
  Future<void> addToCart({
    required int productId,
    required String productName,
    required double unitPrice,
    String imageUrl = '',
    int quantity = 1,
  }) =>
      _notifier.addToCart(
        productId: productId,
        productName: productName,
        unitPrice: unitPrice,
        imageUrl: imageUrl,
        quantity: quantity,
      );

  /// Update quantity of a cart item.
  Future<void> updateQuantity(int cartItemId, int quantity) =>
      _notifier.updateQuantity(cartItemId, quantity);

  /// Remove a single item from cart.
  Future<void> removeFromCart(int cartItemId) =>
      _notifier.removeFromCart(cartItemId);

  /// Clear all items from cart.
  Future<void> clearCart() => _notifier.clearCart();

  /// Get the total price of all items.
  double getTotalPrice(List<CartItemDisplay> items) {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  /// Get total item count.
  int getItemCount(List<CartItemDisplay> items) {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }
}