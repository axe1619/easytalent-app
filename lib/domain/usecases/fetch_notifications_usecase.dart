import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

class FetchNotificationsUseCase {
  final NotificationRepository repository;

  FetchNotificationsUseCase(this.repository);

  Future<NotificationResponse> execute(int page) {
    return repository.getUnreadNotifications(page);
  }
}
