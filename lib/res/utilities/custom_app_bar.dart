import 'package:flutter/material.dart';
import '../consts/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../horilla_main/notifications_list.dart';
import '../../domain/usecases/fetch_notifications_usecase.dart';
import '../../domain/usecases/get_unread_count_usecase.dart';
import '../../domain/usecases/delete_notification_usecase.dart';
import '../../domain/usecases/delete_notifications_usecase.dart';

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
      );
    } else {
      // Fallback a navegación si no hay casos de uso
      Navigator.pushNamed(context, AppRoutes.home);
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
            if (notificationsCount != null && notificationsCount! > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Center(
                    child: Text(
                      notificationsCount! > 99 ? '99+' : '$notificationsCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}