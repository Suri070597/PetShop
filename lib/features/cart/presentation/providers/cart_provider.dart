import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../data/cart_repository.dart';
import '../../domain/cart_item_model.dart';

/// Một sản phẩm trong giỏ hàng kèm thông tin dùng để hiển thị.
class CartItemDisplay {
  final int cartItemId;
  final int productId;
  final String productName;
  final String imageUrl;
  final int quantity;
  final double unitPrice;

  const CartItemDisplay({
    required this.cartItemId,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.quantity,
    required this.unitPrice,
  });

  /// Thành tiền của một sản phẩm.
  double get totalPrice => quantity * unitPrice;
}

/// Xác định userId dùng cho giỏ hàng.
///
/// - Nếu đăng nhập Firebase hợp lệ: sử dụng Firebase UID.
/// - Nếu chưa đăng nhập: sử dụng `guest`.
///
/// Guest vẫn được phép thêm sản phẩm vào giỏ, nhưng Checkout sẽ yêu cầu
/// đăng nhập trước khi tạo đơn hàng.
final currentCartUserIdProvider = Provider<String>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final preferences = ref.watch(preferencesServiceProvider);

  final firebaseUser = authRepository.firebaseUser;
  final savedUserId = preferences.currentUserId;

  final isLoggedIn =
      firebaseUser != null &&
      firebaseUser.emailVerified &&
      savedUserId != null &&
      savedUserId == firebaseUser.uid;

  if (isLoggedIn) {
    return firebaseUser.uid;
  }

  return 'guest';
});

/// Provider quản lý trạng thái giỏ hàng.
final cartProvider = StateNotifierProvider<
    CartNotifier,
    AsyncValue<List<CartItemDisplay>>>(
  (ref) {
    final repository = ref.watch(cartRepositoryProvider);
    final userId = ref.watch(currentCartUserIdProvider);

    return CartNotifier(
      repository,
      ref,
      userId,
    );
  },
);

/// Quản lý dữ liệu và các thao tác của giỏ hàng.
class CartNotifier
    extends StateNotifier<AsyncValue<List<CartItemDisplay>>> {
  final CartRepository _repository;
  final Ref _ref;

  String _currentUserId;

  CartNotifier(
    this._repository,
    this._ref,
    this._currentUserId,
  ) : super(const AsyncValue.loading());

  /// Cập nhật userId hiện tại.
  ///
  /// Hàm này không tự load lại giỏ hàng để tránh việc load nhiều lần.
  void setUserId(String userId) {
    if (_currentUserId == userId) {
      return;
    }

    _currentUserId = userId;

    // Xóa dữ liệu của user cũ khỏi giao diện trong lúc chờ load lại.
    state = const AsyncValue.loading();
  }

  /// Chuyển giỏ hàng guest sang tài khoản vừa đăng nhập.
  ///
  /// Trường hợp:
  /// 1. Người dùng chưa đăng nhập và thêm sản phẩm vào giỏ guest.
  /// 2. Người dùng đăng nhập.
  /// 3. Các sản phẩm guest được chuyển sang giỏ của Firebase UID.
  Future<void> migrateGuestCartToCurrentUser() async {
    if (_currentUserId == 'guest') {
      return;
    }

    final guestItems = await _repository.getCartItems('guest');

    if (guestItems.isEmpty) {
      return;
    }

    final currentUserItems =
        await _repository.getCartItems(_currentUserId);

    for (final guestItem in guestItems) {
      CartItem? existingItem;

      for (final currentItem in currentUserItems) {
        if (currentItem.productId == guestItem.productId) {
          existingItem = currentItem;
          break;
        }
      }

      if (existingItem != null) {
        // Sản phẩm đã có trong giỏ của user:
        // cộng số lượng guest vào số lượng hiện tại.
        await _repository.updateQuantity(
          existingItem.cartItemId,
          existingItem.quantity + guestItem.quantity,
        );
      } else {
        // Sản phẩm chưa có trong giỏ user:
        // thêm một CartItem mới cho Firebase UID.
        await _repository.addToCart(
          userId: _currentUserId,
          productId: guestItem.productId,
          unitPrice: guestItem.unitPrice,
          quantity: guestItem.quantity,
        );
      }
    }

    // Sau khi chuyển thành công, xóa giỏ guest.
    await _repository.clearCart('guest');
  }

  /// Tải tất cả sản phẩm thuộc giỏ hàng của user hiện tại.
  Future<void> loadCart() async {
    state = const AsyncValue.loading();

    try {
      final items = await _repository.getCartItems(
        _currentUserId,
      );

      final displayItems = await _enrichItems(items);

      state = AsyncValue.data(displayItems);
    } catch (error, stackTrace) {
      state = AsyncValue.error(
        error,
        stackTrace,
      );
    }
  }

  /// Thêm sản phẩm vào giỏ hàng.
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

      await loadCart();
    } catch (error, stackTrace) {
      state = AsyncValue.error(
        error,
        stackTrace,
      );

      rethrow;
    }
  }

  /// Cập nhật số lượng sản phẩm.
  Future<void> updateQuantity(
    int cartItemId,
    int quantity,
  ) async {
    try {
      if (quantity <= 0) {
        await _repository.removeFromCart(cartItemId);
      } else {
        await _repository.updateQuantity(
          cartItemId,
          quantity,
        );
      }

      await loadCart();
    } catch (error, stackTrace) {
      state = AsyncValue.error(
        error,
        stackTrace,
      );

      rethrow;
    }
  }

  /// Xóa một sản phẩm khỏi giỏ hàng.
  Future<void> removeFromCart(int cartItemId) async {
    try {
      await _repository.removeFromCart(cartItemId);
      await loadCart();
    } catch (error, stackTrace) {
      state = AsyncValue.error(
        error,
        stackTrace,
      );

      rethrow;
    }
  }

  /// Xóa toàn bộ giỏ hàng của user hiện tại.
  Future<void> clearCart() async {
    try {
      await _repository.clearCart(_currentUserId);
      await loadCart();
    } catch (error, stackTrace) {
      state = AsyncValue.error(
        error,
        stackTrace,
      );

      rethrow;
    }
  }

  /// Bổ sung tên và ảnh sản phẩm từ ProductRepository.
  Future<List<CartItemDisplay>> _enrichItems(
    List<CartItem> items,
  ) async {
    final productRepository = _ref.read(
      productRepositoryImplProvider,
    );

    final result = <CartItemDisplay>[];

    for (final item in items) {
      String productName = 'Sản phẩm #${item.productId}';
      String imageUrl = '';

      try {
        final product = await productRepository.getById(
          item.productId.toString(),
        );

        if (product != null) {
          productName = product.name;
          imageUrl = product.image;
        }
      } catch (_) {
        // Nếu không lấy được Product thì giữ giá trị mặc định.
      }

      result.add(
        CartItemDisplay(
          cartItemId: item.cartItemId,
          productId: item.productId,
          productName: productName,
          imageUrl: imageUrl,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
        ),
      );
    }

    return result;
  }
}