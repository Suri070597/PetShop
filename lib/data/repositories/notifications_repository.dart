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

  /// Seed welcome notifications if the user doesn't have any yet.
  Future<void> ensureWelcomeNotifications(String userId) async {
    final queryCount = _database.selectOnly(_database.notifications)
      ..addColumns([_database.notifications.notificationId.count()])
      ..where(_database.notifications.userId.equals(userId));

    final count = await queryCount.map((row) => row.read(_database.notifications.notificationId.count()) ?? 0).getSingle();
    
    if (count == 0) {
      await _database.into(_database.notifications).insert(
        NotificationsCompanion.insert(
          userId: userId,
          title: 'Chào mừng bạn đến với PetJoy!',
          content: 'Cảm ơn bạn đã lựa chọn PetJoy làm người bạn đồng hành chăm sóc bé cưng. Chúc bạn có trải nghiệm mua sắm tuyệt vời!',
          isRead: const Value(false),
          createdAt: Value(DateTime.now().subtract(const Duration(minutes: 30))),
        ),
      );
      
      await _database.into(_database.notifications).insert(
        NotificationsCompanion.insert(
          userId: userId,
          title: 'Mã giảm giá thành viên mới 🎉',
          content: 'Bạn được tặng mã PETJOYNEW giảm ngay 15% cho đơn hàng đầu tiên. Sử dụng ngay tại phần thanh toán nhé!',
          isRead: const Value(false),
          createdAt: Value(DateTime.now().subtract(const Duration(hours: 2))),
        ),
      );
    }
  }
}
