import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cart_provider.dart';

/// Provider cung cấp các thao tác giỏ hàng cho giao diện.
final cartControllerProvider = Provider<CartController>(
  (ref) {
    return CartController(ref);
  },
);

/// Controller quản lý các hành động từ giao diện Cart.
class CartController {
  final Ref _ref;

  CartController(this._ref);

  /// Lấy CartNotifier.
  CartNotifier get _notifier {
    return _ref.read(cartProvider.notifier);
  }

  /// Đồng bộ lại userId trước mỗi thao tác.
  ///
  /// Provider được invalidate để tránh sử dụng userId cũ đã được cache
  /// từ thời điểm trước khi đăng nhập.
  Future<String> _synchronizeCurrentUser({
    bool migrateGuestCart = true,
  }) async {
    _ref.invalidate(currentCartUserIdProvider);

    final userId = _ref.read(
      currentCartUserIdProvider,
    );

    _notifier.setUserId(userId);

    // Nếu người dùng vừa đăng nhập, chuyển sản phẩm guest
    // sang giỏ hàng thuộc Firebase UID.
    if (migrateGuestCart && userId != 'guest') {
      await _notifier.migrateGuestCartToCurrentUser();
    }

    return userId;
  }

  /// Tải giỏ hàng theo đúng user hiện tại.
  Future<void> loadCart() async {
    await _synchronizeCurrentUser();
    await _notifier.loadCart();
  }

  /// Thêm sản phẩm vào giỏ hàng.
  Future<void> addToCart({
    required int productId,
    required String productName,
    required double unitPrice,
    String imageUrl = '',
    int quantity = 1,
  }) async {
    await _synchronizeCurrentUser();

    await _notifier.addToCart(
      productId: productId,
      productName: productName,
      unitPrice: unitPrice,
      imageUrl: imageUrl,
      quantity: quantity,
    );
  }

  /// Cập nhật số lượng sản phẩm.
  Future<void> updateQuantity(
    int cartItemId,
    int quantity,
  ) async {
    await _synchronizeCurrentUser();

    await _notifier.updateQuantity(
      cartItemId,
      quantity,
    );
  }

  /// Xóa một sản phẩm khỏi giỏ hàng.
  Future<void> removeFromCart(int cartItemId) async {
    await _synchronizeCurrentUser();

    await _notifier.removeFromCart(cartItemId);
  }

  /// Xóa toàn bộ giỏ hàng.
  Future<void> clearCart() async {
    await _synchronizeCurrentUser(
      migrateGuestCart: false,
    );

    await _notifier.clearCart();
  }

  /// Tính tổng tiền của giỏ hàng.
  double getTotalPrice(
    List<CartItemDisplay> items,
  ) {
    return items.fold(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );
  }

  /// Tính tổng số lượng sản phẩm.
  int getItemCount(
    List<CartItemDisplay> items,
  ) {
    return items.fold(
      0,
      (sum, item) => sum + item.quantity,
    );
  }
}