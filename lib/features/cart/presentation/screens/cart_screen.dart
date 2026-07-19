import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../controllers/cart_controller.dart';
import '../providers/cart_provider.dart';
import '../widgets/cart_item_widget.dart';

/// Cart screen with full cart management.
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  static const routeName = RouteNames.cart;

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  void initState() {
    super.initState();
    // Load cart on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cartControllerProvider).loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);
    final controller = ref.read(cartControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Giỏ hàng'),
        actions: [
          IconButton(
            tooltip: 'Lịch sử đơn hàng',
            onPressed: () => Navigator.pushNamed(
              context,
              RouteNames.orderHistory,
            ),
            icon: const Icon(Icons.receipt_long_outlined),
          ),
          // Delete all button
          cartAsync.whenOrNull(
            data: (items) => items.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Xóa tất cả',
              onPressed: () => _confirmClearCart(context, controller),
            )
                : null,
          ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
              const SizedBox(height: 16),
              Text(
                'Không thể tải giỏ hàng',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => controller.loadCart(),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return _buildEmptyCart();
          }
          return _buildCartContent(items, controller);
        },
      ),
    );
  }

  /// Build empty cart state.
  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.mist,
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 60,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Giỏ hàng trống',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Hãy thêm sản phẩm vào giỏ hàng để mua sắm',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.muted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, RouteNames.home),
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Mua sắm ngay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forest,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build cart content with items list and bottom bar.
  Widget _buildCartContent(
      List<CartItemDisplay> items, CartController controller) {
    final totalPrice = controller.getTotalPrice(items);
    final itemCount = controller.getItemCount(items);

    return Column(
      children: [
        // Cart items list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return CartItemWidget(
                item: item,
                onQuantityChanged: (newQuantity) {
                  controller.updateQuantity(item.cartItemId, newQuantity);
                },
                onRemove: () => _confirmRemoveItem(
                  context,
                  controller,
                  item,
                ),
              );
            },
          ),
        ),

        // Bottom summary bar
        Container(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                // Summary row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tạm tính ($itemCount sản phẩm):',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.muted,
                      ),
                    ),
                    Text(
                      MoneyFormatter.usd(totalPrice),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.forest,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Checkout button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      RouteNames.checkout,
                    ),
                    icon: const Icon(Icons.payment),
                    label: const Text(
                      'Thanh toán',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Show confirmation dialog before removing a single item.
  void _confirmRemoveItem(
      BuildContext context,
      CartController controller,
      CartItemDisplay item,
      ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa sản phẩm'),
        content: Text('Bạn có chắc muốn xóa "${item.productName}" khỏi giỏ hàng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.removeFromCart(item.cartItemId);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  /// Show confirmation dialog before clearing the entire cart.
  void _confirmClearCart(BuildContext context, CartController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa tất cả'),
        content: const Text('Bạn có chắc muốn xóa tất cả sản phẩm khỏi giỏ hàng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.clearCart();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
  }
}