import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/repositories/reviews_repository.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../products/presentation/widgets/write_review_sheet.dart';
import '../../domain/order_models.dart';
import '../providers/order_provider.dart';
import '../utils/order_status_helper.dart';

/// Màn hình chức năng 30 và 32:
/// - View order detail
/// - Order tracking
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({
    super.key,
    required this.orderId,
  });

  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text('Đơn hàng #$orderId'),
        actions: [
          IconButton(
            tooltip: 'Lịch sử đơn hàng',
            onPressed: () => Navigator.pushNamed(
              context,
              RouteNames.orderHistory,
            ),
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _DetailError(
          message: _friendlyError(error),
          onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
        ),
        data: (data) {
          if (data == null) {
            return const Center(child: Text('Không tìm thấy đơn hàng.'));
          }
          return _buildContent(context, ref, data);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    OrderDetailViewData data,
  ) {
    final order = data.order;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
      children: [
        _OrderHeaderCard(data: data),
        const SizedBox(height: 16),
        _DetailSection(
          title: 'Theo dõi đơn hàng',
          icon: Icons.route_outlined,
          child: _OrderTracking(status: order.orderStatus),
        ),
        const SizedBox(height: 16),
        _DetailSection(
          title: 'Sản phẩm (${data.lines.length})',
          icon: Icons.shopping_bag_outlined,
          child: Column(
            children: [
              for (var index = 0; index < data.lines.length; index++) ...[
                _OrderProductRow(
                  line: data.lines[index],
                  isDelivered: order.orderStatus == 'Delivered',
                ),
                if (index != data.lines.length - 1)
                  const Divider(height: 26),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _DetailSection(
          title: 'Địa chỉ nhận hàng',
          icon: Icons.location_on_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.address.receiverName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(data.address.phone),
              const SizedBox(height: 6),
              Text(
                '${data.address.street}, ${data.address.ward}, '
                '${data.address.district}, ${data.address.province}',
                style: const TextStyle(
                  height: 1.4,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _DetailSection(
          title: 'Thanh toán',
          icon: Icons.payment_outlined,
          child: Column(
            children: [
              _TextInfoRow(
                label: 'Phương thức',
                value: OrderStatusHelper.paymentMethodLabel(
                  order.paymentMethod,
                ),
              ),
              const SizedBox(height: 10),
              _TextInfoRow(
                label: 'Trạng thái',
                value: OrderStatusHelper.paymentLabel(order.paymentStatus),
              ),
              const Divider(height: 28),
              _MoneyInfoRow(label: 'Tạm tính', value: data.subTotal),
              const SizedBox(height: 10),
              _MoneyInfoRow(
                label: 'Phí vận chuyển',
                value: order.shippingFee,
              ),
              const SizedBox(height: 10),
              _MoneyInfoRow(
                label: 'Giảm giá',
                value: -order.discountAmount,
              ),
              const Divider(height: 28),
              _MoneyInfoRow(
                label: 'Tổng thanh toán',
                value: order.totalAmount,
                emphasized: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            if (OrderStatusHelper.canCancel(order.orderStatus)) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmCancel(context, ref, order.orderId),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Hủy đơn'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _reorder(context, ref, order.orderId),
                icon: const Icon(Icons.replay_outlined),
                label: const Text('Mua lại'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.forest,
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmCancel(
    BuildContext context,
    WidgetRef ref,
    int id,
  ) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hủy đơn hàng'),
        content: const Text(
          'Bạn chắc chắn muốn hủy đơn? Tồn kho sẽ được hoàn lại.',
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
        const SnackBar(
          content: Text('Vui lòng đăng nhập để hủy đơn hàng.'),
        ),
      );
      return;
    }

    try {
      await ref.read(orderRepositoryProvider).cancelOrder(
            orderId: id,
            userId: userId,
          );

      ref.invalidate(orderDetailProvider(id));
      ref.invalidate(orderHistoryProvider);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hủy đơn hàng.')),
      );
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(error))),
      );
    }
  }


  Future<void> _reorder(
    BuildContext context,
    WidgetRef ref,
    int id,
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
      final result = await ref.read(orderRepositoryProvider).reorder(
            orderId: id,
            userId: userId,
          );

      await ref.read(cartControllerProvider).loadCart();

      if (!context.mounted) {
        return;
      }

      final warning =
          result.hasWarnings ? '\n${result.warnings.join('\n')}' : '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã thêm ${result.addedQuantity} sản phẩm vào giỏ.$warning',
          ),
        ),
      );

      if (result.addedQuantity > 0) {
        Navigator.pushNamed(context, RouteNames.cart);
      }
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(error))),
      );
    }
  }


  static String _friendlyError(Object error) {
    return error
        .toString()
        .replaceFirst('Bad state: ', '')
        .replaceFirst('Exception: ', '');
  }
}

class _OrderHeaderCard extends StatelessWidget {
  const _OrderHeaderCard({required this.data});

  final OrderDetailViewData data;

  @override
  Widget build(BuildContext context) {
    final order = data.order;
    final statusColor = OrderStatusHelper.color(order.orderStatus);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Đơn hàng #${order.orderId}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  OrderStatusHelper.label(order.orderStatus),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Ngày đặt: ${DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate)}',
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _OrderTracking extends StatelessWidget {
  const _OrderTracking({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    if (status == 'Cancelled') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel, color: AppColors.danger),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Đơn hàng đã được hủy.',
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final currentIndex = OrderStatusHelper.progressIndex(status);

    return Column(
      children: List.generate(OrderStatusHelper.progressStatuses.length, (
        index,
      ) {
        final stepStatus = OrderStatusHelper.progressStatuses[index];
        final completed = index <= currentIndex;
        final isCurrent = index == currentIndex;
        final isLast = index == OrderStatusHelper.progressStatuses.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 30,
                child: Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: completed ? AppColors.forest : AppColors.mist,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: completed ? AppColors.forest : AppColors.line,
                        ),
                      ),
                      child: Icon(
                        completed ? Icons.check : Icons.circle,
                        size: completed ? 15 : 8,
                        color: completed ? Colors.white : AppColors.muted,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: index < currentIndex
                              ? AppColors.forest
                              : AppColors.line,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        OrderStatusHelper.label(stepStatus),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isCurrent ? FontWeight.w900 : FontWeight.w700,
                          color: completed ? AppColors.ink : AppColors.muted,
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(height: 4),
                        const Text(
                          'Trạng thái hiện tại',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.forest,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.forest),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _OrderProductRow extends ConsumerWidget {
  const _OrderProductRow({
    required this.line,
    this.isDelivered = false,
  });

  final OrderProductLine line;
  final bool isDelivered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentShoppingUserIdProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 70,
                height: 70,
                color: AppColors.mist,
                child: line.imageUrl.isEmpty
                    ? const Icon(Icons.pets, color: AppColors.muted)
                    : Image.network(
                        line.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.pets, color: AppColors.muted),
                      ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${MoneyFormatter.vndFromLegacy(line.price)} × ${line.quantity}',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              MoneyFormatter.vndFromLegacy(line.subTotal),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.forest,
              ),
            ),
          ],
        ),
        if (isDelivered && userId != null) ...[
          const SizedBox(height: 8),
          ref
              .watch(
                reviewEligibilityProvider('${userId}_${line.productId}'),
              )
              .when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (eligibility) {
                  final isReviewed =
                      eligibility.status ==
                      ReviewEligibilityStatus.alreadyReviewedAllPurchases;

                  return Align(
                    alignment: Alignment.centerRight,
                    child: isReviewed
                        ? OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.forest,
                              side: const BorderSide(color: AppColors.forest),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () async {
                              final review = await ref
                                  .read(reviewsRepositoryProvider)
                                  .getUserReviewForProduct(
                                    userId,
                                    line.productId,
                                  );
                              if (context.mounted && review != null) {
                                showViewMyReviewDialog(
                                  context,
                                  review: review,
                                  productName: line.productName,
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.remove_red_eye_outlined,
                              size: 16,
                            ),
                            label: const Text(
                              'Xem đánh giá',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.forest,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              showWriteReviewBottomSheet(
                                context,
                                ref,
                                productId: line.productId,
                                productName: line.productName,
                                onReviewSubmitted: () {
                                  ref.invalidate(reviewEligibilityProvider);
                                  ref.invalidate(orderHistoryProvider);
                                },
                              );
                            },
                            icon: const Icon(
                              Icons.rate_review_outlined,
                              size: 16,
                            ),
                            label: const Text(
                              'Viết đánh giá',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  );
                },
              ),
        ],
      ],
    );
  }
}

class _TextInfoRow extends StatelessWidget {
  const _TextInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: AppColors.muted)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _MoneyInfoRow extends StatelessWidget {
  const _MoneyInfoRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final double value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: emphasized ? 17 : 15,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
              color: emphasized ? AppColors.ink : AppColors.muted,
            ),
          ),
        ),
        Text(
          MoneyFormatter.vndFromLegacy(value),
          style: TextStyle(
            fontSize: emphasized ? 22 : 16,
            fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
            color: emphasized ? AppColors.forest : AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}

/// Helper dialog to display user's review details.
void showViewMyReviewDialog(
  BuildContext context, {
  required ReviewDisplay review,
  required String productName,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.rate_review_outlined, color: AppColors.forest),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Đánh giá của bạn',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            productName,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (idx) {
              return Icon(
                idx < review.rating ? Icons.star : Icons.star_border,
                color: AppColors.honey,
                size: 24,
              );
            }),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.mist,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              review.comment.isEmpty ? 'Không có bình luận.' : review.comment,
              style: const TextStyle(fontSize: 14, color: AppColors.ink),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Thời gian: ${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng', style: TextStyle(color: AppColors.forest, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}
