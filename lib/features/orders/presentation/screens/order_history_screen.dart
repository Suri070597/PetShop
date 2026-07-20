import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/datasources/drift/app_database.dart' as drift_db;
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../providers/order_provider.dart';
import '../utils/order_status_helper.dart';

/// Màn hình chức năng 28, 31 và 33:
/// - View order history
/// - Reorder
/// - Cancel order
class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(orderHistoryProvider);

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
      body: RefreshIndicator(
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
            if (orders.isEmpty) {
              return const _EmptyOrderHistory();
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final order = orders[index];
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
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );

    if (accepted != true || !context.mounted) {
      return;
    }

    try {
      final userId = ref.read(currentShoppingUserIdProvider);
      await ref.read(orderRepositoryProvider).cancelOrder(
            orderId: order.orderId,
            userId: userId,
          );

      ref.invalidate(orderHistoryProvider);
      ref.invalidate(orderDetailProvider(order.orderId));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hủy đơn hàng thành công.')),
        );
      }
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyError(error))),
        );
      }
    }
  }

  Future<void> _reorder(
    BuildContext context,
    WidgetRef ref,
    int orderId,
  ) async {
    try {
      final userId = ref.read(currentShoppingUserIdProvider);
      final result = await ref.read(orderRepositoryProvider).reorder(
            orderId: orderId,
            userId: userId,
          );

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$message$warningText')),
      );

      if (result.addedQuantity > 0) {
        Navigator.pushNamed(context, RouteNames.cart);
      }
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyError(error))),
        );
      }
    }
  }

  static String _friendlyError(Object error) {
    return error
        .toString()
        .replaceFirst('Bad state: ', '')
        .replaceFirst('Exception: ', '');
  }
}

class _OrderHistoryCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final statusColor = OrderStatusHelper.color(order.orderStatus);
    final dateText = DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate);

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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Đơn hàng #${order.orderId}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
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
              const SizedBox(height: 9),
              Text(
                dateText,
                style: const TextStyle(color: AppColors.muted),
              ),
              const Divider(height: 28),
              _InfoRow(
                icon: Icons.payment_outlined,
                label: OrderStatusHelper.paymentMethodLabel(
                  order.paymentMethod,
                ),
              ),
              const SizedBox(height: 9),
              _InfoRow(
                icon: Icons.account_balance_wallet_outlined,
                label: OrderStatusHelper.paymentLabel(order.paymentStatus),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Tổng cộng',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.muted,
                    ),
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
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
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
