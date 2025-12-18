import '../models/notification_model.dart';

abstract class NotificationRepository {
  Future<NotificationResponse> getUnreadNotifications(int page);
  Future<int> getUnreadNotificationsCount();
  Future<void> markAllAsRead();
  Future<NotificationResponse> getAllNotifications();
  Future<void> deleteNotification(int id);
  Future<void> bulkDeleteNotifications();
}
