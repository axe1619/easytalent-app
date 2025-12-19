import 'package:flutter/material.dart';
import '../consts/app_colors.dart';
import '../../horilla_main/notifications_list.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/usecases/fetch_notifications_usecase.dart';
import '../../domain/usecases/get_unread_count_usecase.dart';
import '../../domain/usecases/delete_notification_usecase.dart';
import '../../domain/usecases/delete_notifications_usecase.dart';
import '../../main.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final int? notificationsCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMenuTap;
  final FetchNotificationsUseCase? fetchNotificationsUseCase;
  final GetUnreadCountUseCase? getUnreadCountUseCase;
  final DeleteNotificationUseCase? deleteNotificationUseCase;
  final BulkDeleteNotificationsUseCase? bulkDeleteNotificationsUseCase;
  final String? employeeName;

  const CustomAppBar({
    Key? key,
    this.title = 'EasyTalent',
    this.notificationsCount,
    this.onNotificationTap,
    this.onMenuTap,
    this.fetchNotificationsUseCase,
    this.getUnreadCountUseCase,
    this.deleteNotificationUseCase,
    this.bulkDeleteNotificationsUseCase,
    this.employeeName,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _showNotificationsModal(BuildContext context) {
    if (fetchNotificationsUseCase != null &&
        getUnreadCountUseCase != null &&
        deleteNotificationUseCase != null &&
        bulkDeleteNotificationsUseCase != null) {
      showDialog(
        context: context,
        builder: (context) => NotificationsModal(
          fetchNotificationsUseCase: fetchNotificationsUseCase!,
          getUnreadCountUseCase: getUnreadCountUseCase!,
          deleteNotificationUseCase: deleteNotificationUseCase!,
          bulkDeleteNotificationsUseCase: bulkDeleteNotificationsUseCase!,
          employeeName: employeeName,
        ),
      ).then((_) {
        notificationManagerService.unreadNotificationsCount();
      });
    } else {
      // Fallback a navegación si no hay casos de uso
      final repository = NotificationRepositoryImpl();
      showDialog(
        context: context,
        builder: (context) => NotificationsModal(
          fetchNotificationsUseCase: FetchNotificationsUseCase(repository),
          getUnreadCountUseCase: GetUnreadCountUseCase(repository),
          deleteNotificationUseCase: DeleteNotificationUseCase(repository),
          bulkDeleteNotificationsUseCase:
              BulkDeleteNotificationsUseCase(repository),
          employeeName: employeeName,
        ),
      ).then((_) {
        notificationManagerService.unreadNotificationsCount();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      forceMaterialTransparency: false,
      backgroundColor: primaryColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.menu,
          color: Colors.white,
        ),
        onPressed: onMenuTap ?? () {
          // El zoom drawer se manejará desde el widget padre
        },
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      automaticallyImplyLeading: false,
      actions: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
              ),
              onPressed: onNotificationTap ?? () {
                _showNotificationsModal(context);
              },
            ),
            if (notificationsCount != null)
              if (notificationsCount! > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: _NotificationsBadge(count: notificationsCount!),
                )
              else
                const SizedBox.shrink()
            else
              ValueListenableBuilder<int>(
                valueListenable: notificationManagerService.unreadCountNotifier,
                builder: (context, count, _) {
                  if (count <= 0) return const SizedBox.shrink();
                  return Positioned(
                    right: 8,
                    top: 8,
                    child: _NotificationsBadge(count: count),
                  );
                },
              ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _NotificationsBadge extends StatelessWidget {
  final int count;

  const _NotificationsBadge({this.count = 0});

  @override
  Widget build(BuildContext context) {
    final displayText = count > 99 ? '99+' : '$count';

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: secondaryColor,
        shape: BoxShape.circle,
      ),
      constraints: const BoxConstraints(
        minWidth: 16,
        minHeight: 16,
      ),
      child: Center(
        child: Text(
          displayText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
