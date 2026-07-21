import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/colors.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../wishlist/presentation/controllers/wishlist_controller.dart';
import '../controllers/notifications_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static const routeName = RouteNames.notifications;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final controller = ref.read(notificationsControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Thông báo'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        actions: [
          if (userId != null)
            notificationsAsync.whenOrNull(
                  data: (list) => list.any((n) => !n.isRead)
                      ? TextButton(
                          onPressed: () => controller.markAllAsRead(),
                          child: const Text(
                            'Đọc tất cả',
                            style: TextStyle(
                              color: AppColors.forest,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : null,
                ) ??
                const SizedBox.shrink(),
        ],
      ),
      body: userId == null
          ? const _GuestNotificationsContent()
          : notificationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.forest)),
              error: (error, _) => Center(
                child: Text('Đã xảy ra lỗi: ${error.toString()}', style: const TextStyle(color: AppColors.danger)),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const _EmptyNotificationsContent();
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEFEFEF)),
                  itemBuilder: (context, index) {
                    final notification = list[index];
                    return _NotificationTile(
                      notification: notification,
                      onTap: () => controller.markAsRead(notification.notificationId),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  final dynamic notification; // Drift Notification class
  final VoidCallback onTap;

  IconData _getIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('đơn hàng') || t.contains('đặt hàng') || t.contains('giao') || t.contains('xác nhận')) {
      if (t.contains('thành công') || t.contains('đã giao')) {
        return Icons.check_circle_outline;
      }
      if (t.contains('đang') || t.contains('giao')) {
        return Icons.local_shipping_outlined;
      }
      return Icons.inventory_2_outlined;
    }
    if (t.contains('mã giảm giá') || t.contains('voucher') || t.contains('khuyến mãi')) {
      return Icons.confirmation_num_outlined;
    }
    return Icons.celebration_outlined;
  }

  Color _getIconColor(String title) {
    final t = title.toLowerCase();
    if (t.contains('đơn hàng') || t.contains('đặt hàng') || t.contains('giao') || t.contains('xác nhận')) {
      if (t.contains('thành công') || t.contains('đã giao')) {
        return AppColors.forest;
      }
      return const Color(0xFF1976D2);
    }
    if (t.contains('mã giảm giá') || t.contains('voucher') || t.contains('khuyến mãi')) {
      return const Color(0xFFE65100);
    }
    return AppColors.forest;
  }

  String _formatTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRead = notification.isRead;
    final title = notification.title as String;
    final iconData = _getIcon(title);
    final iconColor = _getIconColor(title);

    return InkWell(
      onTap: () {
        if (!isRead) onTap();
        final t = title.toLowerCase();
        if (t.contains('đơn hàng') || t.contains('đặt hàng') || t.contains('giao')) {
          Navigator.pushNamed(context, RouteNames.orderHistory);
        } else if (t.contains('mã giảm giá') || t.contains('voucher')) {
          Navigator.pushNamed(context, RouteNames.vouchers);
        }
      },
      child: Container(
        color: isRead ? Colors.transparent : iconColor.withValues(alpha: 0.04),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isRead ? AppColors.mist : iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: isRead ? AppColors.muted : iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 15,
                            fontWeight: isRead ? FontWeight.w700 : FontWeight.w900,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: const BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.content,
                    style: TextStyle(
                      color: isRead ? AppColors.muted : AppColors.ink,
                      fontSize: 13.5,
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(notification.createdAt),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyNotificationsContent extends StatelessWidget {
  const _EmptyNotificationsContent();

  @override
  Widget build(BuildContext context) {
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
                Icons.notifications_off_outlined,
                size: 60,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chưa có thông báo',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Các thông báo về đơn hàng, khuyến mãi sẽ xuất hiện ở đây nhé!',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.muted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestNotificationsContent extends StatelessWidget {
  const _GuestNotificationsContent();

  @override
  Widget build(BuildContext context) {
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
                Icons.notifications_outlined,
                size: 60,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Bạn chưa đăng nhập',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Đăng nhập để xem danh sách thông báo của bạn.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.muted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Đăng nhập',
              icon: Icons.login,
              onPressed: () => Navigator.pushReplacementNamed(context, RouteNames.login),
            ),
          ],
        ),
      ),
    );
  }
}
