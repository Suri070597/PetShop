import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../../../data/datasources/drift/app_database.dart' as drift_db;
import '../domain/order_models.dart';

/// Repository xử lý toàn bộ nghiệp vụ Checkout và Order bằng Drift.
///
/// Các thao tác quan trọng như tạo đơn, hủy đơn và mua lại đều chạy trong
/// transaction để dữ liệu Orders, OrderDetails, Products và CartItems luôn
/// đồng bộ với nhau.
class OrderRepository {
  OrderRepository(this._db);

  final drift_db.AppDatabase _db;

  /// Không có màn hình Admin nên đơn Pending sẽ tự chuyển sang Confirmed
  /// sau 2 phút kể từ lúc đặt hàng.
  /// Vì project chưa có Admin nên trạng thái đơn hàng sẽ tự động thay đổi.
  ///
  /// Mỗi bước kéo dài 2 phút:
  /// Pending → Confirmed → Preparing → Shipping → Delivered.
  static const Duration automaticStatusStep = Duration(minutes: 2);

  /// Thứ tự các trạng thái trong quá trình giao hàng.
  static const List<String> _automaticStatuses = [
    'Pending',
    'Confirmed',
    'Preparing',
    'Shipping',
    'Delivered',
  ];

  /// Phí giao hàng demo: miễn phí từ 50.000 VND, ngược lại phí 5.000 VND.
  static double calculateShippingFee(double subTotal) {
    return subTotal >= 50 ? 0 : 5;
  }

  /// Đảm bảo chế độ test không đăng nhập vẫn có một người dùng local hợp lệ.
  Future<void> ensureUserExists(String userId) async {
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

  /// Lấy địa chỉ mặc định hoặc địa chỉ được tạo gần nhất của người dùng.
  Future<drift_db.AddressesData?> getDefaultAddress(String userId) async {
    await ensureUserExists(userId);

    final query = _db.select(_db.addresses)
      ..where((table) => table.userId.equals(userId))
      ..orderBy([
            (table) => OrderingTerm.desc(table.isDefault),
            (table) => OrderingTerm.desc(table.addressId),
      ])
      ..limit(1);

    return query.getSingleOrNull();
  }

  /// Tạo đơn hàng từ toàn bộ sản phẩm đang có trong giỏ.
  Future<int> checkout({
    required String userId,
    required CheckoutAddressInput address,
    required String paymentMethod,
    int? voucherId,
    double discountAmount = 0.0,
  }) async {
    return _db.transaction(() async {
      await ensureUserExists(userId);

      final cartRows = await (_db.select(_db.cartItems)
        ..where((table) => table.userId.equals(userId)))
          .get();

      if (cartRows.isEmpty) {
        throw StateError('Giỏ hàng đang trống.');
      }

      // Kiểm tra sản phẩm và tồn kho trước khi ghi bất kỳ dữ liệu đơn hàng nào.
      final validatedLines = <_ValidatedCartLine>[];
      double subTotal = 0;

      for (final cart in cartRows) {
        final product = await (_db.select(_db.products)
          ..where((table) => table.productId.equals(cart.productId)))
            .getSingleOrNull();

        if (product == null || !product.status) {
          throw StateError(
            'Sản phẩm #${cart.productId} không còn được bán.',
          );
        }

        if (product.stockQuantity < cart.quantity) {
          throw StateError(
            '${product.productName} chỉ còn ${product.stockQuantity} sản phẩm.',
          );
        }

        validatedLines.add(
          _ValidatedCartLine(cart: cart, product: product),
        );
        subTotal += cart.unitPrice * cart.quantity;
      }

      final addressId = await _saveDefaultAddress(
        userId: userId,
        input: address,
      );

      final shippingFee = calculateShippingFee(subTotal);
      final finalDiscount = math.max(0.0, discountAmount);
      final totalAmount = math.max(0.0, subTotal + shippingFee - finalDiscount);

      final orderId = await _db.into(_db.orders).insert(
        drift_db.OrdersCompanion.insert(
          userId: userId,
          addressId: addressId,
          totalAmount: totalAmount,
          shippingFee: Value(shippingFee),
          discountAmount: Value(finalDiscount),
          voucherId: voucherId != null ? Value(voucherId) : const Value.absent(),
          paymentMethod: Value(paymentMethod),
          paymentStatus: Value(
            PaymentMethodCodes.initialPaymentStatus(paymentMethod),
          ),
          orderStatus: const Value('Pending'),
        ),
      );

      if (voucherId != null) {
        await _db.customStatement(
          'UPDATE vouchers SET used_count = used_count + 1 WHERE voucher_id = ?',
          [voucherId],
        );
      }

      for (final line in validatedLines) {
        final cart = line.cart;
        final product = line.product;

        await _db.into(_db.orderDetails).insert(
          drift_db.OrderDetailsCompanion.insert(
            orderId: orderId,
            productId: cart.productId,
            quantity: cart.quantity,
            price: cart.unitPrice,
            subTotal: cart.unitPrice * cart.quantity,
          ),
        );

        // Trừ tồn kho ngay trong cùng transaction.
        await (_db.update(_db.products)
          ..where((table) => table.productId.equals(product.productId)))
            .write(
          drift_db.ProductsCompanion(
            stockQuantity: Value(product.stockQuantity - cart.quantity),
          ),
        );
      }

      // Chỉ xóa giỏ hàng sau khi Orders và OrderDetails đã được tạo thành công.
      await (_db.delete(_db.cartItems)
        ..where((table) => table.userId.equals(userId)))
          .go();

      return orderId;
    });
  }

  /// Lấy vị trí của một trạng thái trong quy trình giao hàng.
  int _getStatusIndex(String status) {
    return _automaticStatuses.indexOf(status);
  }

  /// Tính trạng thái hiện tại dựa vào thời gian đặt hàng.
  ///
  /// Ví dụ:
  /// - Dưới 2 phút: Pending.
  /// - Từ 2 đến dưới 4 phút: Confirmed.
  /// - Từ 4 đến dưới 6 phút: Preparing.
  /// - Từ 6 đến dưới 8 phút: Shipping.
  /// - Từ 8 phút trở lên: Delivered.
  String calculateAutomaticStatus(DateTime orderDate) {
    final now = DateTime.now().toUtc();
    final createdAt = orderDate.toUtc();
    final elapsed = now.difference(createdAt);

    // Tránh trường hợp thời gian thiết bị bị sai và orderDate nằm trong tương lai.
    if (elapsed.isNegative) {
      return 'Pending';
    }

    final secondsPerStep = automaticStatusStep.inSeconds;

    // Số bước đã trôi qua kể từ khi đặt đơn.
    final stepIndex = elapsed.inSeconds ~/ secondsPerStep;

    // Nếu đã đi qua tất cả các bước thì đơn đã được giao.
    if (stepIndex >= _automaticStatuses.length - 1) {
      return 'Delivered';
    }

    return _automaticStatuses[stepIndex];
  }

  /// Trả về thời điểm đơn hàng sẽ chuyển sang trạng thái tiếp theo.
  ///
  /// Trả về null nếu đơn đã giao hoặc đã hủy.
  DateTime? nextAutomaticStatusTime(drift_db.Order order) {
    final orderDate = order.orderDate.toUtc();
    final stepSeconds = automaticStatusStep.inSeconds;

    switch (order.orderStatus) {
      case 'Pending':
        return orderDate.add(
          Duration(seconds: stepSeconds),
        );

      case 'Confirmed':
        return orderDate.add(
          Duration(seconds: stepSeconds * 2),
        );

      case 'Preparing':
        return orderDate.add(
          Duration(seconds: stepSeconds * 3),
        );

      case 'Shipping':
        return orderDate.add(
          Duration(seconds: stepSeconds * 4),
        );

      case 'Delivered':
      case 'Cancelled':
      default:
        return null;
    }
  }

  /// Kiểm tra và cập nhật trạng thái mới nhất của một đơn hàng.
  ///
  /// Hàm này không dựa hoàn toàn vào Timer. Vì vậy, khi người dùng tắt ứng dụng
  /// rồi mở lại, đơn hàng vẫn được chuyển thẳng tới trạng thái đúng.
  Future<bool> updateAutomaticOrderStatus({
    required int orderId,
    required String userId,
  }) async {
    final order = await (_db.select(_db.orders)
      ..where(
            (table) =>
        table.orderId.equals(orderId) &
        table.userId.equals(userId),
      ))
        .getSingleOrNull();

    if (order == null) {
      return false;
    }

    // Không cập nhật đơn đã bị hủy.
    if (order.orderStatus == 'Cancelled') {
      return false;
    }

    // Đơn đã giao thì không cần tiếp tục cập nhật.
    if (order.orderStatus == 'Delivered') {
      return false;
    }

    final newStatus = calculateAutomaticStatus(order.orderDate);

    final currentStatusIndex = _getStatusIndex(order.orderStatus);
    final newStatusIndex = _getStatusIndex(newStatus);

    // Không cập nhật nếu trạng thái chưa đến bước tiếp theo.
    //
    // Việc so sánh index cũng giúp trạng thái không bị chạy ngược,
    // ví dụ Shipping không bị quay lại Confirmed.
    if (newStatusIndex <= currentStatusIndex) {
      return false;
    }

    // COD được xem là đã thanh toán khi đơn được giao thành công.
    final shouldMarkCodAsPaid =
        newStatus == 'Delivered' &&
            order.paymentMethod == PaymentMethodCodes.cod &&
            order.paymentStatus == 'Pending';

    final affectedRows = await (_db.update(_db.orders)
      ..where(
            (table) =>
        table.orderId.equals(orderId) &
        table.userId.equals(userId) &
        // Kiểm tra trạng thái một lần nữa để tránh trường hợp
        // người dùng vừa hủy đơn trong khi Timer đang chạy.
        table.orderStatus.equals(order.orderStatus),
      ))
        .write(
      drift_db.OrdersCompanion(
        orderStatus: Value(newStatus),
        paymentStatus: shouldMarkCodAsPaid
            ? const Value('Paid')
            : const Value.absent(),
      ),
    );

    return affectedRows > 0;
  }

  /// Cập nhật tất cả đơn hàng chưa hoàn thành của một người dùng.
  Future<int> updateAllAutomaticOrderStatuses(String userId) async {
    final orders = await (_db.select(_db.orders)
      ..where((table) => table.userId.equals(userId)))
        .get();

    int updatedCount = 0;

    for (final order in orders) {
      if (order.orderStatus == 'Cancelled' ||
          order.orderStatus == 'Delivered') {
        continue;
      }

      final changed = await updateAutomaticOrderStatus(
        orderId: order.orderId,
        userId: userId,
      );

      if (changed) {
        updatedCount++;
      }
    }

    return updatedCount;
  }




  /// Lịch sử đơn hàng của đúng người dùng hiện tại, mới nhất ở trên cùng.
  /// Lịch sử đơn hàng của đúng người dùng hiện tại, mới nhất ở trên cùng.
  Future<List<drift_db.Order>> getOrders(String userId) async {
    await ensureUserExists(userId);

    // Trước khi đọc danh sách, cập nhật trạng thái tất cả đơn hàng.
    await updateAllAutomaticOrderStatuses(userId);

    final query = _db.select(_db.orders)
      ..where((table) => table.userId.equals(userId))
      ..orderBy([
            (table) => OrderingTerm.desc(table.orderDate),
      ]);

    return query.get();
  }

  /// Lấy đơn hàng, địa chỉ và danh sách sản phẩm để hiển thị chi tiết.
  Future<OrderDetailViewData?> getOrderDetail({
    required int orderId,
    required String userId,
  }) async {
    await updateAutomaticOrderStatus(
      orderId: orderId,
      userId: userId,
    );

    final order = await (_db.select(_db.orders)
      ..where(
            (table) =>
        table.orderId.equals(orderId) & table.userId.equals(userId),
      ))
        .getSingleOrNull();

    if (order == null) {
      return null;
    }

    final address = await (_db.select(_db.addresses)
      ..where((table) => table.addressId.equals(order.addressId)))
        .getSingleOrNull();

    if (address == null) {
      throw StateError('Không tìm thấy địa chỉ của đơn hàng.');
    }

    final details = await (_db.select(_db.orderDetails)
      ..where((table) => table.orderId.equals(orderId)))
        .get();

    final lines = <OrderProductLine>[];
    for (final detail in details) {
      final product = await (_db.select(_db.products)
        ..where((table) => table.productId.equals(detail.productId)))
          .getSingleOrNull();

      lines.add(
        OrderProductLine(
          orderDetailId: detail.orderDetailId,
          productId: detail.productId,
          productName: product?.productName ?? 'Sản phẩm #${detail.productId}',
          imageUrl: product?.thumbnail ?? '',
          quantity: detail.quantity,
          price: detail.price,
          subTotal: detail.subTotal,
        ),
      );
    }

    return OrderDetailViewData(
      order: order,
      address: address,
      lines: lines,
    );
  }

  /// Khách hàng chỉ được hủy đơn Pending hoặc Confirmed.
  /// Khi hủy, số lượng sản phẩm được cộng lại vào kho.
  Future<void> cancelOrder({
    required int orderId,
    required String userId,
  }) async {
    await _db.transaction(() async {
      final order = await (_db.select(_db.orders)
        ..where(
              (table) =>
          table.orderId.equals(orderId) & table.userId.equals(userId),
        ))
          .getSingleOrNull();

      if (order == null) {
        throw StateError('Không tìm thấy đơn hàng.');
      }

      if (order.orderStatus != 'Pending' &&
          order.orderStatus != 'Confirmed') {
        throw StateError('Đơn hàng ở trạng thái này không thể hủy.');
      }

      final details = await (_db.select(_db.orderDetails)
        ..where((table) => table.orderId.equals(orderId)))
          .get();

      for (final detail in details) {
        final product = await (_db.select(_db.products)
          ..where((table) => table.productId.equals(detail.productId)))
            .getSingleOrNull();

        if (product == null) {
          continue;
        }

        await (_db.update(_db.products)
          ..where((table) => table.productId.equals(detail.productId)))
            .write(
          drift_db.ProductsCompanion(
            stockQuantity: Value(product.stockQuantity + detail.quantity),
          ),
        );
      }

      final newPaymentStatus = order.paymentStatus == 'Paid'
          ? 'Refunded'
          : 'Cancelled';

      await (_db.update(_db.orders)
        ..where((table) => table.orderId.equals(orderId)))
          .write(
        drift_db.OrdersCompanion(
          orderStatus: const Value('Cancelled'),
          paymentStatus: Value(newPaymentStatus),
        ),
      );
    });
  }

  /// Đưa sản phẩm của đơn cũ trở lại giỏ hàng.
  /// Sản phẩm ngừng bán hoặc hết hàng sẽ được bỏ qua và trả về trong warnings.
  Future<ReorderResult> reorder({
    required int orderId,
    required String userId,
  }) async {
    return _db.transaction(() async {
      await ensureUserExists(userId);

      final order = await (_db.select(_db.orders)
        ..where(
              (table) =>
          table.orderId.equals(orderId) & table.userId.equals(userId),
        ))
          .getSingleOrNull();

      if (order == null) {
        throw StateError('Không tìm thấy đơn hàng để mua lại.');
      }

      final details = await (_db.select(_db.orderDetails)
        ..where((table) => table.orderId.equals(orderId)))
          .get();

      int addedQuantity = 0;
      final warnings = <String>[];

      for (final detail in details) {
        final product = await (_db.select(_db.products)
          ..where((table) => table.productId.equals(detail.productId)))
            .getSingleOrNull();

        if (product == null || !product.status) {
          warnings.add('Sản phẩm #${detail.productId} đã ngừng bán');
          continue;
        }

        final existing = await (_db.select(_db.cartItems)
          ..where(
                (table) =>
            table.userId.equals(userId) &
            table.productId.equals(detail.productId),
          ))
            .getSingleOrNull();

        final existingQuantity = existing?.quantity ?? 0;
        final availableToAdd = product.stockQuantity - existingQuantity;

        if (availableToAdd <= 0) {
          warnings.add('${product.productName} đã hết số lượng có thể thêm');
          continue;
        }

        final quantityToAdd =
        math.min(detail.quantity, availableToAdd).toInt();
        final currentPrice = product.discountPrice ?? product.price;

        if (existing == null) {
          await _db.into(_db.cartItems).insert(
            drift_db.CartItemsCompanion.insert(
              userId: userId,
              productId: detail.productId,
              quantity: Value(quantityToAdd),
              unitPrice: currentPrice,
            ),
          );
        } else {
          await (_db.update(_db.cartItems)
            ..where(
                  (table) => table.cartItemId.equals(existing.cartItemId),
            ))
              .write(
            drift_db.CartItemsCompanion(
              quantity: Value(existingQuantity + quantityToAdd),
              unitPrice: Value(currentPrice),
            ),
          );
        }

        addedQuantity += quantityToAdd;

        if (quantityToAdd < detail.quantity) {
          warnings.add(
            '${product.productName}: chỉ thêm được $quantityToAdd/${detail.quantity}',
          );
        }
      }

      if (addedQuantity == 0 && warnings.isEmpty) {
        warnings.add('Đơn hàng cũ không có sản phẩm để mua lại');
      }

      return ReorderResult(
        addedQuantity: addedQuantity,
        warnings: warnings,
      );
    });
  }

  /// Lưu địa chỉ đang nhập thành địa chỉ mặc định.
  Future<int> _saveDefaultAddress({
    required String userId,
    required CheckoutAddressInput input,
  }) async {
    await (_db.update(_db.addresses)
      ..where((table) => table.userId.equals(userId)))
        .write(
      const drift_db.AddressesCompanion(
        isDefault: Value(false),
      ),
    );

    if (input.addressId != null) {
      final ownedAddress = await (_db.select(_db.addresses)
        ..where(
              (table) =>
          table.addressId.equals(input.addressId!) &
          table.userId.equals(userId),
        ))
          .getSingleOrNull();

      if (ownedAddress != null) {
        await (_db.update(_db.addresses)
          ..where((table) => table.addressId.equals(input.addressId!)))
            .write(
          drift_db.AddressesCompanion(
            receiverName: Value(input.receiverName.trim()),
            phone: Value(input.phone.trim()),
            province: Value(input.province.trim()),
            district: Value(input.district.trim()),
            ward: Value(input.ward.trim()),
            street: Value(input.street.trim()),
            isDefault: const Value(true),
          ),
        );
        return input.addressId!;
      }
    }

    return _db.into(_db.addresses).insert(
      drift_db.AddressesCompanion.insert(
        userId: userId,
        receiverName: input.receiverName.trim(),
        phone: input.phone.trim(),
        province: input.province.trim(),
        district: input.district.trim(),
        ward: input.ward.trim(),
        street: input.street.trim(),
        isDefault: const Value(true),
      ),
    );
  }
}


class _ValidatedCartLine {
  const _ValidatedCartLine({
    required this.cart,
    required this.product,
  });

  final drift_db.CartItem cart;
  final drift_db.Product product;
}
