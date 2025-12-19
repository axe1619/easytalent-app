import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'custom_drawer_menu.dart';
import 'custom_app_bar.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/usecases/delete_notification_usecase.dart';
import '../../domain/usecases/delete_notifications_usecase.dart';
import '../../domain/usecases/get_unread_count_usecase.dart';
import '../../domain/usecases/fetch_notifications_usecase.dart';

class DrawerWrapper extends StatelessWidget {
  final Widget child;
  final String appBarTitle;
  final int? notificationsCount;
  final VoidCallback? onNotificationTap;
  final Map<String, dynamic>? userData;
  final Future<void> Function()? onLogout;
  final VoidCallback? onSettingsTap;
  final List<Map<String, dynamic>>? customMenuItems;
  final FetchNotificationsUseCase? fetchNotificationsUseCase;
  final GetUnreadCountUseCase? getUnreadCountUseCase;
  final DeleteNotificationUseCase? deleteNotificationUseCase;
  final BulkDeleteNotificationsUseCase? bulkDeleteNotificationsUseCase;
  final String? employeeName;

  const DrawerWrapper({
    Key? key,
    required this.child,
    this.appBarTitle = 'EasyTalent',
    this.notificationsCount,
    this.onNotificationTap,
    this.userData,
    this.onLogout,
    this.onSettingsTap,
    this.customMenuItems,
    this.fetchNotificationsUseCase,
    this.getUnreadCountUseCase,
    this.deleteNotificationUseCase,
    this.bulkDeleteNotificationsUseCase,
    this.employeeName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool hasAllNotificationDeps = fetchNotificationsUseCase != null &&
        getUnreadCountUseCase != null &&
        deleteNotificationUseCase != null &&
        bulkDeleteNotificationsUseCase != null;

    final notificationRepository = NotificationRepositoryImpl();
    final FetchNotificationsUseCase effectiveFetchNotificationsUseCase =
        hasAllNotificationDeps
            ? fetchNotificationsUseCase!
            : FetchNotificationsUseCase(notificationRepository);
    final GetUnreadCountUseCase effectiveGetUnreadCountUseCase =
        hasAllNotificationDeps
            ? getUnreadCountUseCase!
            : GetUnreadCountUseCase(notificationRepository);
    final DeleteNotificationUseCase effectiveDeleteNotificationUseCase =
        hasAllNotificationDeps
            ? deleteNotificationUseCase!
            : DeleteNotificationUseCase(notificationRepository);
    final BulkDeleteNotificationsUseCase effectiveBulkDeleteNotificationsUseCase =
        hasAllNotificationDeps
            ? bulkDeleteNotificationsUseCase!
            : BulkDeleteNotificationsUseCase(notificationRepository);

    return ZoomDrawer(
      menuScreen: CustomDrawerMenu(
        userData: userData,
        onLogout: () async {
          await onLogout?.call();
        },
        onSettingsTap: onSettingsTap,
        customMenuItems: customMenuItems,
      ),
      mainScreen: Builder(
        builder: (BuildContext scaffoldContext) {
          return Scaffold(
            appBar: CustomAppBar(
              title: appBarTitle,
              notificationsCount: notificationsCount,
              onNotificationTap: onNotificationTap,
              onMenuTap: () {
                final zoomDrawer = ZoomDrawer.of(scaffoldContext);
                if (zoomDrawer != null) {
                  zoomDrawer.toggle();
                }
              },
              fetchNotificationsUseCase: effectiveFetchNotificationsUseCase,
              getUnreadCountUseCase: effectiveGetUnreadCountUseCase,
              deleteNotificationUseCase: effectiveDeleteNotificationUseCase,
              bulkDeleteNotificationsUseCase:
                  effectiveBulkDeleteNotificationsUseCase,
              employeeName: employeeName,
            ),
            body: child,
          );
        },
      ),
      borderRadius: 24.0,
      showShadow: true,
      angle: -12.0,
      slideWidth: MediaQuery.of(context).size.width * 0.7,
      menuBackgroundColor: Colors.deepOrangeAccent,
    );
  }
}
