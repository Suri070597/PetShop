import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../data/datasources/drift/app_database.dart';
import '../../../wishlist/presentation/controllers/wishlist_controller.dart';

/// Stream provider for user notifications.
final notificationsStreamProvider = StreamProvider.autoDispose<List<Notification>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream.value([]);
  }
  
  // Call welcome notification seeding
  final repo = ref.watch(notificationsRepositoryProvider);
  repo.ensureWelcomeNotifications(userId);
  
  return repo.watchNotifications(userId);
});

/// Provider to count unread notifications.
final unreadNotificationsCountProvider = Provider.autoDispose<int>((ref) {
  final notificationsAsync = ref.watch(notificationsStreamProvider);
  return notificationsAsync.when(
    data: (list) => list.where((n) => !n.isRead).length,
    loading: () => 0,
    error: (e, s) => 0,
  );
});

/// Controller to handle notification actions.
class NotificationsController {
  final Ref _ref;

  NotificationsController(this._ref);

  /// Mark a single notification as read.
  Future<void> markAsRead(int notificationId) async {
    final repo = _ref.read(notificationsRepositoryProvider);
    await repo.markAsRead(notificationId);
    _ref.invalidate(notificationsStreamProvider);
  }

  /// Mark all notifications as read.
  Future<void> markAllAsRead() async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;
    final repo = _ref.read(notificationsRepositoryProvider);
    await repo.markAllAsRead(userId);
    _ref.invalidate(notificationsStreamProvider);
  }
}

final notificationsControllerProvider = Provider<NotificationsController>((ref) {
  return NotificationsController(ref);
});
