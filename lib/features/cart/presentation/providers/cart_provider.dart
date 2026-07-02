import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../data/cart_repository.dart';
import '../../domain/cart_item_model.dart';

/// Represents a cart item with product details for display.
class CartItemDisplay {
  final int cartItemId;
  final int productId;
  final String productName;
  final String imageUrl;
  final int quantity;
  final double unitPrice;

  CartItemDisplay({
    required this.cartItemId,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.quantity,
    required this.unitPrice,
  });

  double get totalPrice => quantity * unitPrice;
}

/// Provider for cart state management.
final cartProvider =
    StateNotifierProvider<CartNotifier, AsyncValue<List<CartItemDisplay>>>(
        (ref) {
  final repository = ref.watch(cartRepositoryProvider);
  return CartNotifier(repository, ref);
});

/// Notifier that manages cart state.
class CartNotifier extends StateNotifier<AsyncValue<List<CartItemDisplay>>> {
  final CartRepository _repository;
  final Ref _ref;
  String _currentUserId = 'guest';

  CartNotifier(this._repository, this._ref)
      : super(const AsyncValue.loading());

  /// Set the current user ID and reload cart.
  void setUserId(String userId) {
    _currentUserId = userId;
    loadCart();
  }

  /// Load all cart items for the current user.
  Future<void> loadCart() async {
    state = const AsyncValue.loading();
    try {
      final items = await _repository.getCartItems(_currentUserId);
      // We need to enrich with product details
      final displayItems = await _enrichItems(items);
      state = AsyncValue.data(displayItems);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Add a product to the cart.
  Future<void> addToCart({
    required int productId,
    required String productName,
    required double unitPrice,
    String imageUrl = '',
    int quantity = 1,
  }) async {
    try {
      await _repository.addToCart(
        userId: _currentUserId,
        productId: productId,
        unitPrice: unitPrice,
        quantity: quantity,
      );
      // Reload cart to get updated state
      await loadCart();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update the quantity of a cart item.
  Future<void> updateQuantity(int cartItemId, int quantity) async {
    try {
      if (quantity <= 0) {
        await _repository.removeFromCart(cartItemId);
      } else {
        await _repository.updateQuantity(cartItemId, quantity);
      }
      await loadCart();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Remove a single item from the cart.
  Future<void> removeFromCart(int cartItemId) async {
    try {
      await _repository.removeFromCart(cartItemId);
      await loadCart();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Clear all items from the cart.
  Future<void> clearCart() async {
    try {
      await _repository.clearCart(_currentUserId);
      await loadCart();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Enrich cart items with product details (name, image) from the DB.
  Future<List<CartItemDisplay>> _enrichItems(List<CartItem> items) async {
    final productRepo = _ref.read(productRepositoryImplProvider);
    final result = <CartItemDisplay>[];

    for (final item in items) {
      String productName = 'Sản phẩm #${item.productId}';
      String imageUrl = '';

      try {
        final product = await productRepo.getById(item.productId.toString());
        if (product != null) {
          productName = product.name;
          imageUrl = product.image;
        }
      } catch (_) {
        // Keep default values
      }

      result.add(CartItemDisplay(
        cartItemId: item.cartItemId,
        productId: item.productId,
        productName: productName,
        imageUrl: imageUrl,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
      ));
    }

    return result;
  }
}