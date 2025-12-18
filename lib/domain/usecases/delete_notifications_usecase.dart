import '../repositories/notification_repository.dart';

class BulkDeleteNotificationsUseCase {
  final NotificationRepository repository;

  BulkDeleteNotificationsUseCase(this.repository);

  Future<void> execute() {
    return repository.bulkDeleteNotifications();
  }
}