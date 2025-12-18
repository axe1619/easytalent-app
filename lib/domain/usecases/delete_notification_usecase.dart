import '../repositories/notification_repository.dart';

class DeleteNotificationUseCase {
  final NotificationRepository repository;

  DeleteNotificationUseCase(this.repository);

  Future<void> execute(int id) {
    return repository.deleteNotification(id);
  }
}