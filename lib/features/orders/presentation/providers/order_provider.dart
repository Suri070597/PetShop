import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../data/datasources/drift/app_database.dart' as drift_db;
import '../../domain/order_models.dart';

/// User hiện tại đang mua hàng.
///
/// Khi tạm thời không đăng nhập, project sử dụng user local tên `guest`.
final currentShoppingUserIdProvider = Provider<String>((ref) {
  return ref.watch(preferencesServiceProvider).currentUserId ?? 'guest';
});

/// Danh sách lịch sử đơn hàng của người dùng hiện tại.
final orderHistoryProvider =
FutureProvider.autoDispose<List<drift_db.Order>>((ref) async {
  final userId = ref.watch(currentShoppingUserIdProvider);
  final repository = ref.watch(orderRepositoryProvider);

  // getOrders sẽ tự cập nhật tất cả trạng thái trước khi trả dữ liệu.
  final orders = await repository.getOrders(userId);

  // Lấy thời điểm chuyển trạng thái tiếp theo của tất cả đơn chưa hoàn thành.
  final nextTimes = orders
      .map(repository.nextAutomaticStatusTime)
      .whereType<DateTime>()
      .toList();

  if (nextTimes.isNotEmpty) {
    // Chọn đơn hàng có thời điểm chuyển trạng thái gần nhất.
    final nearestTime = nextTimes.reduce(
          (first, second) {
        return first.isBefore(second) ? first : second;
      },
    );

    final remaining = nearestTime.difference(
      DateTime.now().toUtc(),
    );

    // Nếu mốc thời gian đã qua thì cập nhật ngay.
    final delay = remaining.isNegative
        ? const Duration(milliseconds: 200)
        : remaining + const Duration(milliseconds: 200);

    final timer = Timer(delay, () async {
      // Cập nhật trạng thái mới nhất của tất cả đơn hàng.
      await repository.updateAllAutomaticOrderStatuses(userId);

      // Tải lại danh sách lịch sử.
      ref.invalidateSelf();
    });

    // Khi rời màn hình thì hủy Timer để tránh rò rỉ bộ nhớ.
    ref.onDispose(timer.cancel);
  }

  return orders;
});

/// Địa chỉ mặc định dùng để điền sẵn trên Checkout screen.
final defaultCheckoutAddressProvider =
FutureProvider.autoDispose<drift_db.AddressesData?>((ref) {
  final userId = ref.watch(currentShoppingUserIdProvider);

  return ref
      .watch(orderRepositoryProvider)
      .getDefaultAddress(userId);
});

/// Dữ liệu chi tiết của một đơn hàng.
final orderDetailProvider =
FutureProvider.autoDispose.family<OrderDetailViewData?, int>(
      (ref, orderId) async {
    final userId = ref.watch(currentShoppingUserIdProvider);
    final repository = ref.watch(orderRepositoryProvider);

    // getOrderDetail sẽ tự cập nhật trạng thái trước khi đọc dữ liệu.
    final data = await repository.getOrderDetail(
      orderId: orderId,
      userId: userId,
    );

    if (data == null) {
      return null;
    }

    // Xác định thời điểm chuyển sang trạng thái tiếp theo.
    final nextStatusTime = repository.nextAutomaticStatusTime(
      data.order,
    );

    if (nextStatusTime != null) {
      final remaining = nextStatusTime.difference(
        DateTime.now().toUtc(),
      );

      final delay = remaining.isNegative
          ? const Duration(milliseconds: 200)
          : remaining + const Duration(milliseconds: 200);

      final timer = Timer(delay, () async {
        await repository.updateAutomaticOrderStatus(
          orderId: orderId,
          userId: userId,
        );

        // Làm mới cả lịch sử và màn hình chi tiết.
        ref.invalidate(orderHistoryProvider);
        ref.invalidateSelf();
      });

      ref.onDispose(timer.cancel);
    }

    return data;
  },
);