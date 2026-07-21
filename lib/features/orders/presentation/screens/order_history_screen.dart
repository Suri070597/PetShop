import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/datasources/drift/app_database.dart' as drift_db;
import '../../../../data/repositories/reviews_repository.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../products/presentation/widgets/write_review_sheet.dart';
import '../../domain/order_models.dart';
import '../providers/order_provider.dart';
import '../utils/order_status_helper.dart';
import 'order_detail_screen.dart';

/// Màn hình chức năng 28, 31 và 33:
/// - View order history
/// - Reorder
/// - Cancel order
class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  int _selectedFilterIndex =
      0; // 0: Tất cả, 1: Chưa giao, 2: Chưa đánh giá, 3: Đã đánh giá

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(orderHistoryProvider);
    final userId = ref.watch(currentShoppingUserIdProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Lịch sử đơn hàng'),
        actions: [
          IconButton(
            tooltip: 'Giỏ hàng',
            onPressed: () => Navigator.pushNamed(context, RouteNames.cart),
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tất cả', 0),
                  const SizedBox(width: 8),
                  _buildFilterChip('Chưa giao', 1),
                  const SizedBox(width: 8),
                  _buildFilterChip('Chưa đánh giá', 2),
                  const SizedBox(width: 8),
                  _buildFilterChip('Đã đánh giá', 3),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(orderHistoryProvider);
                await ref.read(orderHistoryProvider.future);
              },
              child: ordersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.7,
                      child: _OrderError(
                        message: _friendlyError(error),
                        onRetry: () => ref.invalidate(orderHistoryProvider),
                      ),
                    ),
                  ],
                ),
                data: (orders) {
                  final filteredOrders = orders.where((order) {
                    if (_selectedFilterIndex == 0) {
                      return true; // Tất cả
                    }

                    if (_selectedFilterIndex == 1) {
                      // Chưa giao (Pending, Confirmed, Preparing, Shipping)
                      return order.orderStatus != 'Delivered' &&
                          order.orderStatus != 'Cancelled';
                    }

                    if (order.orderStatus != 'Delivered' || userId == null) {
                      return false;
                    }

                    final isFullyReviewed = ref
                        .watch(
                          orderIsFullyReviewedProvider((
                            userId: userId,
                            orderId: order.orderId,
                          )),
                        )
                        .valueOrNull;

                    if (_selectedFilterIndex == 2) {
                      // Chưa đánh giá: còn sản phẩm chưa đánh giá (isFullyReviewed == false)
                      return isFullyReviewed == false;
                    }

                    if (_selectedFilterIndex == 3) {
                      // Đã đánh giá: đã đánh giá toàn bộ (isFullyReviewed == true)
                      return isFullyReviewed == true;
                    }

                    return true;
                  }).toList();

                  if (filteredOrders.isEmpty) {
                    return const _EmptyOrderHistory();
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
                    itemCount: filteredOrders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return _OrderHistoryCard(
                        order: order,
                        onViewDetail: () => Navigator.pushNamed(
                          context,
                          RouteNames.orderDetail,
                          arguments: order.orderId,
                        ),
                        onCancel: OrderStatusHelper.canCancel(order.orderStatus)
                            ? () => _confirmCancel(context, ref, order)
                            : null,
                        onReorder: () => _reorder(context, ref, order.orderId),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedFilterIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilterIndex = index),
      selectedColor: AppColors.forest,
      labelStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: isSelected ? Colors.white : AppColors.ink,
        fontSize: 13,
      ),
      backgroundColor: AppColors.mist,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Future<void> _confirmCancel(
    BuildContext context,
    WidgetRef ref,
    drift_db.Order order,
  ) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hủy đơn hàng'),
        content: Text(
          'Bạn có chắc muốn hủy đơn #${order.orderId}? Số lượng sản phẩm sẽ được hoàn lại kho.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Không'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );

    if (accepted != true || !context.mounted) {
      return;
    }

    final userId = ref.read(currentShoppingUserIdProvider);

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để hủy đơn hàng.')),
      );
      return;
    }

    try {
      await ref
          .read(orderRepositoryProvider)
          .cancelOrder(orderId: order.orderId, userId: userId);

      ref.invalidate(orderHistoryProvider);
      ref.invalidate(orderDetailProvider(order.orderId));

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hủy đơn hàng thành công.')),
      );
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
    }
  }

  Future<void> _reorder(
    BuildContext context,
    WidgetRef ref,
    int orderId,
  ) async {
    final userId = ref.read(currentShoppingUserIdProvider);

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để mua lại đơn hàng.'),
        ),
      );
      return;
    }

    try {
      final result = await ref
          .read(orderRepositoryProvider)
          .reorder(orderId: orderId, userId: userId);

      await ref.read(cartControllerProvider).loadCart();

      if (!context.mounted) {
        return;
      }

      final message = result.addedQuantity > 0
          ? 'Đã thêm ${result.addedQuantity} sản phẩm vào giỏ.'
          : 'Không có sản phẩm nào được thêm.';

      final warningText = result.hasWarnings
          ? '\n${result.warnings.join('\n')}'
          : '';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$message$warningText')));

      if (result.addedQuantity > 0) {
        Navigator.pushNamed(context, RouteNames.cart);
      }
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
    }
  }

  static String _friendlyError(Object error) {
    return error
        .toString()
        .replaceFirst('Bad state: ', '')
        .replaceFirst('Exception: ', '');
  }
}

class _OrderHistoryCard extends ConsumerWidget {
  const _OrderHistoryCard({
    required this.order,
    required this.onViewDetail,
    required this.onReorder,
    this.onCancel,
  });

  final drift_db.Order order;
  final VoidCallback onViewDetail;
  final VoidCallback onReorder;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = OrderStatusHelper.color(order.orderStatus);
    final dateText = DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate);
    final orderDetailAsync = ref.watch(orderDetailProvider(order.orderId));

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onViewDetail,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Mã đơn + Trạng thái
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.mist,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Mã đơn: #ORD-${order.orderId}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      OrderStatusHelper.label(order.orderStatus),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                dateText,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const Divider(height: 24),

              // Product Preview Item
              orderDetailAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (orderDetail) {
                  if (orderDetail == null || orderDetail.lines.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final firstLine = orderDetail.lines.first;
                  final otherItemsCount = orderDetail.lines.length - 1;

                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              firstLine.imageUrl,
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 54,
                                height: 54,
                                color: AppColors.mist,
                                child: const Icon(
                                  Icons.pets,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  firstLine.productName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'Số lượng: x${firstLine.quantity}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                    if (otherItemsCount > 0) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.mist,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          '+$otherItemsCount sản phẩm khác',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.forest,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(
                            MoneyFormatter.usd(firstLine.subTotal),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              ),

              _InfoRow(
                icon: Icons.payment_outlined,
                label: OrderStatusHelper.paymentMethodLabel(
                  order.paymentMethod,
                ),
              ),
              const SizedBox(height: 6),
              _InfoRow(
                icon: Icons.account_balance_wallet_outlined,
                label: OrderStatusHelper.paymentLabel(order.paymentStatus),
              ),
              if (order.orderStatus == 'Delivered') ...[
                const SizedBox(height: 12),
                _OrderReviewBanner(orderId: order.orderId),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text(
                    'Tổng cộng',
                    style: TextStyle(fontSize: 15, color: AppColors.muted),
                  ),
                  const Spacer(),
                  Text(
                    MoneyFormatter.usd(order.totalAmount),
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: AppColors.forest,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (onCancel != null) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onCancel,
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Hủy đơn'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReorder,
                      icon: const Icon(Icons.replay_outlined),
                      label: const Text('Mua lại'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: onViewDetail,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.forest,
                      ),
                      child: const Text('Chi tiết'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: AppColors.muted),
        const SizedBox(width: 9),
        Expanded(
          child: Text(label, style: const TextStyle(color: AppColors.ink)),
        ),
      ],
    );
  }
}

class _EmptyOrderHistory extends StatelessWidget {
  const _EmptyOrderHistory();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    size: 82,
                    color: AppColors.muted,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Bạn chưa có đơn hàng',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () => Navigator.pushReplacementNamed(
                      context,
                      RouteNames.home,
                    ),
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text('Mua sắm ngay'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderError extends StatelessWidget {
  const _OrderError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 62, color: AppColors.danger),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

class _OrderReviewBanner extends ConsumerWidget {
  const _OrderReviewBanner({required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentShoppingUserIdProvider);
    final orderDetailAsync = ref.watch(orderDetailProvider(orderId));

    return orderDetailAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (orderDetail) {
        if (orderDetail == null ||
            orderDetail.lines.isEmpty ||
            userId == null) {
          return const SizedBox.shrink();
        }

        final lines = orderDetail.lines;
        OrderProductLine? unreviewedLine;
        OrderProductLine? reviewedLine;

        for (final line in lines) {
          final eligibility = ref
              .watch(reviewEligibilityProvider('${userId}_${line.productId}'))
              .valueOrNull;

          if (eligibility?.status == ReviewEligibilityStatus.canReview) {
            unreviewedLine ??= line;
          } else if (eligibility?.status ==
              ReviewEligibilityStatus.alreadyReviewedAllPurchases) {
            reviewedLine ??= line;
          }
        }

        final hasUnreviewed = unreviewedLine != null;
        final targetLine = unreviewedLine ?? reviewedLine ?? lines.first;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: hasUnreviewed
                ? AppColors.forest.withValues(alpha: 0.08)
                : AppColors.mist,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasUnreviewed
                  ? AppColors.forest.withValues(alpha: 0.25)
                  : AppColors.line,
            ),
          ),
          child: Row(
            children: [
              Icon(
                hasUnreviewed ? Icons.stars_rounded : Icons.check_circle,
                color: hasUnreviewed ? AppColors.forest : AppColors.muted,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasUnreviewed
                      ? 'Đơn hàng đã giao! Hãy đánh giá sản phẩm để chia sẻ cảm nhận nhé.'
                      : '✓ Bạn đã hoàn thành đánh giá cho đơn hàng này.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: hasUnreviewed ? AppColors.forest : AppColors.muted,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () async {
                  if (hasUnreviewed) {
                    showWriteReviewBottomSheet(
                      context,
                      ref,
                      productId: targetLine.productId,
                      productName: targetLine.productName,
                      onReviewSubmitted: () {
                        ref.invalidate(reviewEligibilityProvider);
                        ref.invalidate(orderHistoryProvider);
                      },
                    );
                  } else {
                    final review = await ref
                        .read(reviewsRepositoryProvider)
                        .getUserReviewForProduct(userId, targetLine.productId);
                    if (context.mounted && review != null) {
                      showViewMyReviewDialog(
                        context,
                        review: review,
                        productName: targetLine.productName,
                      );
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: hasUnreviewed ? AppColors.forest : Colors.white,
                    border: hasUnreviewed
                        ? null
                        : Border.all(color: AppColors.forest),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    hasUnreviewed ? 'Đánh giá' : 'Xem đánh giá',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: hasUnreviewed ? Colors.white : AppColors.forest,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
