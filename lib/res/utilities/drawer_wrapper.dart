import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'custom_drawer_menu.dart';
import 'custom_app_bar.dart';
import '../consts/app_colors.dart';

class DrawerWrapper extends StatelessWidget {
  final Widget child;
  final String appBarTitle;
  final int? notificationsCount;
  final VoidCallback? onNotificationTap;
  final Map<String, dynamic>? userData;
  final Future<void> Function()? onLogout;
  final VoidCallback? onSettingsTap; // Agregar este parámetro
  final List<Map<String, dynamic>>? customMenuItems; // Agregar parámetro para opciones personalizadas

  const DrawerWrapper({
    Key? key,
    required this.child,
    this.appBarTitle = 'EasyTalent',
    this.notificationsCount,
    this.onNotificationTap,
    this.userData,
    this.onLogout,
    this.onSettingsTap, // Agregar este parámetro
    this.customMenuItems,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ZoomDrawer(
      menuScreen: CustomDrawerMenu(
        userData: userData,
        onLogout: () async {
          await onLogout?.call();
        },
        onSettingsTap: onSettingsTap, // Pasar el callback
        customMenuItems: customMenuItems, // Pasar aquí
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
            ),
            body: child,
          );
        },
      ),
      borderRadius: 24.0,
      showShadow: true,
      angle: -12.0, // Cambiado de 0.0 a -12.0
      slideWidth: MediaQuery.of(context).size.width * 0.7,
      menuBackgroundColor: Colors.deepOrangeAccent,
    );
  }
}