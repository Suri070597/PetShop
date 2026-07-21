import 'package:drift/drift.dart';
import '../datasources/drift/app_database.dart';

class NotificationsRepository {
  final AppDatabase _database;

  NotificationsRepository(this._database);

  /// Watch notifications for a user.
  Stream<List<Notification>> watchNotifications(String userId) {
    final query = _database.select(_database.notifications)
      ..where((t) => t.userId.equals(userId))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    
    return query.watch();
  }

  /// Mark a notification as read.
  Future<void> markAsRead(int notificationId) async {
    await (_database.update(_database.notifications)
          ..where((t) => t.notificationId.equals(notificationId)))
        .write(const NotificationsCompanion(isRead: Value(true)));
  }

  /// Mark all notifications as read for a user.
  Future<void> markAllAsRead(String userId) async {
    await (_database.update(_database.notifications)
          ..where((t) => t.userId.equals(userId)))
        .write(const NotificationsCompanion(isRead: Value(true)));
  }

  /// Send an order status notification to a user.
  Future<void> sendOrderNotification({
    required String userId,
    required int orderId,
    required String title,
    required String content,
  }) async {
    await _database.into(_database.notifications).insert(
          NotificationsCompanion.insert(
            userId: userId,
            title: title,
            content: content,
            isRead: const Value(false),
            createdAt: Value(DateTime.now()),
          ),
        );
  }

  /// Seed welcome & order status notifications if the user doesn't have any yet.
  Future<void> ensureWelcomeNotifications(String userId) async {
    final queryCount = _database.selectOnly(_database.notifications)
      ..addColumns([_database.notifications.notificationId.count()])
      ..where(_database.notifications.userId.equals(userId));

    final count = await queryCount
        .map((row) => row.read(_database.notifications.notificationId.count()) ?? 0)
        .getSingle();

    if (count == 0) {
      // 1. Thông báo Giao hàng thành công
      await _database.into(_database.notifications).insert(
        NotificationsCompanion.insert(
          userId: userId,
          title: 'Giao hàng thành công đơn #ORD-100 ✅',
          content: 'Đơn hàng #ORD-100 đã giao thành công. Hãy vào Lịch sử đơn hàng để Đánh giá sản phẩm và nhận ưu đãi nhé!',
          isRead: const Value(true),
          createdAt: Value(DateTime.now().subtract(const Duration(minutes: 45))),
        ),
      );

      // 2. Thông báo Đang giao hàng
      await _database.into(_database.notifications).insert(
        NotificationsCompanion.insert(
          userId: userId,
          title: 'Đơn hàng #ORD-101 đang được giao 🚚',
          content: 'Đơn hàng #ORD-101 đang trên đường vận chuyển tới địa chỉ của bạn. Vui lòng chú ý điện thoại từ shipper!',
          isRead: const Value(false),
          createdAt: Value(DateTime.now().subtract(const Duration(hours: 2))),
        ),
      );

      // 3. Thông báo Đặt hàng thành công
      await _database.into(_database.notifications).insert(
        NotificationsCompanion.insert(
          userId: userId,
          title: 'Xác nhận đơn hàng #ORD-102 📦',
          content: 'Đơn hàng #ORD-102 của bạn đã được tiếp nhận thành công và đang được chuẩn bị đóng gói.',
          isRead: const Value(false),
          createdAt: Value(DateTime.now().subtract(const Duration(hours: 5))),
        ),
      );

      // 4. Thông báo Voucher
      await _database.into(_database.notifications).insert(
        NotificationsCompanion.insert(
          userId: userId,
          title: 'Mã giảm giá thành viên mới 🎉',
          content: 'Bạn được tặng mã PETJOYNEW giảm ngay 15% cho đơn hàng đầu tiên. Sử dụng ngay tại phần thanh toán nhé!',
          isRead: const Value(false),
          createdAt: Value(DateTime.now().subtract(const Duration(hours: 12))),
        ),
      );

      // 5. Thông báo chào mừng
      await _database.into(_database.notifications).insert(
        NotificationsCompanion.insert(
          userId: userId,
          title: 'Chào mừng bạn đến với PetJoy! 🐾',
          content: 'Cảm ơn bạn đã lựa chọn PetJoy làm người bạn đồng hành chăm sóc bé cưng. Chúc bạn có trải nghiệm mua sắm tuyệt vời!',
          isRead: const Value(true),
          createdAt: Value(DateTime.now().subtract(const Duration(days: 2))),
        ),
      );
    }
  }
}
