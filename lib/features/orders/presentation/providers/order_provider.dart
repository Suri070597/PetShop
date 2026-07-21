import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../data/datasources/drift/app_database.dart'
    as drift_db;
import '../../domain/order_models.dart';

import '../../../../data/repositories/reviews_repository.dart';
import '../../../auth/providers/auth_controller.dart';

/// Provider kiểm tra quyền đánh giá theo chuỗi key 'userId_productId'.
final reviewEligibilityProvider = FutureProvider.family
    .autoDispose<ReviewEligibility, String>(
  (ref, key) async {
    final parts = key.split('_');
    if (parts.length < 2) {
      return ReviewEligibility(
        status: ReviewEligibilityStatus.notPurchased,
        deliveredCount: 0,
        reviewCount: 0,
      );
    }
    final userId = parts[0];
    final productId = int.tryParse(parts[1]) ?? 0;
    final repository = ref.watch(reviewsRepositoryProvider);
    return repository.checkReviewEligibility(userId, productId);
  },
);

/// Provider kiểm tra trạng thái đánh giá toàn bộ đơn hàng.
final orderIsFullyReviewedProvider = FutureProvider.family
    .autoDispose<bool, ({String userId, int orderId})>(
  (ref, arg) async {
    final orderDetail = await ref.watch(orderDetailProvider(arg.orderId).future);
    if (orderDetail == null || orderDetail.lines.isEmpty) return false;

    final repository = ref.watch(reviewsRepositoryProvider);
    for (final line in orderDetail.lines) {
      final eligibility = await repository.checkReviewEligibility(arg.userId, line.productId);
      if (eligibility.status == ReviewEligibilityStatus.canReview) {
        return false;
      }
    }
    return true;
  },
);

/// User đang đăng nhập và được phép sử dụng chức năng Order.
final currentShoppingUserIdProvider = Provider<String?>((ref) {
  final authUser = ref.watch(authControllerProvider).valueOrNull;
  if (authUser != null) {
    return authUser.id;
  }
  final prefUserId = ref.watch(preferencesServiceProvider).currentUserId;
  final fbUser = ref.watch(authRepositoryProvider).firebaseUser;

  return prefUserId ?? fbUser?.uid;
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