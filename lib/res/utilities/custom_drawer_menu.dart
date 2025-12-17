import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import '../consts/app_colors.dart';
import '../../core/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'alertDialogs.dart';

class CustomDrawerMenu extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final Future<void> Function()? onLogout;
  final VoidCallback? onSettingsTap; // Agregar este parámetro
  final List<Map<String, dynamic>>? customMenuItems; // Nuevo parámetro

  const CustomDrawerMenu({
    Key? key,
    this.userData,
    this.onLogout,
    this.onSettingsTap, // Agregar este parámetro
    this.customMenuItems, // Nuevo parámetro
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String userName = userData?['employee_name'] ?? '';
    final String? userEmail = userData?['email'];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.deepOrangeAccent,
            Colors.deepOrangeAccent.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header con logo/icono
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    child: Image.asset(
                      'Assets/easy-logo.png',
                      width: 60,
                      height: 60,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  if (userEmail != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      userEmail,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(
              color: Colors.white24,
              thickness: 1,
            ),
            // Opciones del menú
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildMenuItem(
                    context: context,
                    icon: Icons.person_outline,
                    title: 'Perfil',
                    onTap: () {
                      ZoomDrawer.of(context)!.close();
                      Navigator.pushNamed(
                        context,
                        AppRoutes.employeesForm,
                        arguments: userData,
                      );
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.dashboard_outlined,
                    title: 'Módulos',
                    onTap: () {
                      ZoomDrawer.of(context)!.close();
                      Navigator.pushNamed(context, AppRoutes.home);
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.settings_outlined,
                    title: 'Configuraciones',
                    onTap: () {
                      ZoomDrawer.of(context)!.close();
                      if (onSettingsTap != null) {
                        onSettingsTap!();
                      }
                    },
                  ),
                  // Agregar las opciones personalizadas si existen
                  if (customMenuItems != null && customMenuItems!.isNotEmpty) ...[
                    const Divider(
                      color: Colors.white24,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                    ...customMenuItems!.map((item) => _buildMenuItem(
                      context: context,
                      icon: item['icon'] ?? Icons.folder_outlined,
                      title: item['title'] ?? '',
                      onTap: () {
                        ZoomDrawer.of(context)!.close();
                        if (item['onTap'] != null) {
                          item['onTap']();
                        }
                      },
                    )),
                  ],
                  const Divider(
                    color: Colors.white24,
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                   _buildMenuItem(
                    context: context,
                    icon: Icons.logout,
                    title: 'Cerrar Sesión',
                    onTap: () async {
                      ZoomDrawer.of(context)!.close();
                      if (onLogout != null) {
                        await AppAlertDialogs.showLogoutConfirmDialog(
                          context: context,
                          onConfirm: () => onLogout!(),
                        );
                      } else {
                        await AppAlertDialogs.showLogoutConfirmDialog(
                          context: context,
                          onConfirm: () => _handleLogout(context),
                        );
                      }
                    },
                    isLogout: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: isLogout ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    String? typedServerUrl = prefs.getString("typed_url");
    await prefs.remove('token');
    
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
        arguments: typedServerUrl,
      );
    }
  }
}