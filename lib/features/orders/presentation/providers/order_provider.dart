import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../data/datasources/drift/app_database.dart'
    as drift_db;
import '../../domain/order_models.dart';

/// User đang đăng nhập và được phép sử dụng chức năng Order.
///
/// Trả về null khi:
/// - Chưa đăng nhập Firebase.
/// - Email chưa xác minh.
/// - User ID trong Preferences không tồn tại.
/// - User ID local không trùng Firebase UID.
final currentShoppingUserIdProvider = Provider<String?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final preferences = ref.watch(preferencesServiceProvider);

  final firebaseUser = authRepository.firebaseUser;
  final savedUserId = preferences.currentUserId;

  if (firebaseUser == null) {
    return null;
  }

  if (!firebaseUser.emailVerified) {
    return null;
  }

  if (savedUserId == null) {
    return null;
  }

  if (savedUserId != firebaseUser.uid) {
    return null;
  }

  return firebaseUser.uid;
});

/// Danh sách lịch sử đơn hàng của người dùng hiện tại.
final orderHistoryProvider =
    FutureProvider.autoDispose<List<drift_db.Order>>(
  (ref) async {
    final userId = ref.watch(
      currentShoppingUserIdProvider,
    );

    // Chưa đăng nhập thì không truy vấn đơn hàng bằng guest.
    if (userId == null) {
      return const <drift_db.Order>[];
    }

    final repository = ref.watch(
      orderRepositoryProvider,
    );

    // getOrders tự cập nhật trạng thái trước khi trả dữ liệu.
    final orders = await repository.getOrders(userId);

    final nextTimes = orders
        .map(repository.nextAutomaticStatusTime)
        .whereType<DateTime>()
        .toList();

    if (nextTimes.isNotEmpty) {
      final nearestTime = nextTimes.reduce(
        (first, second) {
          return first.isBefore(second)
              ? first
              : second;
        },
      );

      final remaining = nearestTime.difference(
        DateTime.now().toUtc(),
      );

      final delay = remaining.isNegative
          ? const Duration(milliseconds: 200)
          : remaining +
              const Duration(milliseconds: 200);

      final timer = Timer(
        delay,
        () async {
          await repository
              .updateAllAutomaticOrderStatuses(
            userId,
          );

          ref.invalidateSelf();
        },
      );

      ref.onDispose(timer.cancel);
    }

    return orders;
  },
);

/// Địa chỉ mặc định dùng tại Checkout Screen.
final defaultCheckoutAddressProvider =
    FutureProvider.autoDispose<drift_db.AddressesData?>(
  (ref) async {
    final userId = ref.watch(
      currentShoppingUserIdProvider,
    );

    if (userId == null) {
      return null;
    }

    return ref
        .watch(orderRepositoryProvider)
        .getDefaultAddress(userId);
  },
);

/// Dữ liệu chi tiết của một đơn hàng.
final orderDetailProvider = FutureProvider.autoDispose
    .family<OrderDetailViewData?, int>(
  (ref, orderId) async {
    final userId = ref.watch(
      currentShoppingUserIdProvider,
    );

    // Chưa đăng nhập thì không cho đọc Order Detail.
    if (userId == null) {
      return null;
    }

    final repository = ref.watch(
      orderRepositoryProvider,
    );

    final data = await repository.getOrderDetail(
      orderId: orderId,
      userId: userId,
    );

    if (data == null) {
      return null;
    }

    final nextStatusTime =
        repository.nextAutomaticStatusTime(
      data.order,
    );

    if (nextStatusTime != null) {
      final remaining = nextStatusTime.difference(
        DateTime.now().toUtc(),
      );

      final delay = remaining.isNegative
          ? const Duration(milliseconds: 200)
          : remaining +
              const Duration(milliseconds: 200);

      final timer = Timer(
        delay,
        () async {
          await repository.updateAutomaticOrderStatus(
            orderId: orderId,
            userId: userId,
          );

          ref.invalidate(orderHistoryProvider);
          ref.invalidateSelf();
        },
      );

      ref.onDispose(timer.cancel);
    }

    return data;
  },
);