import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../consts/app_colors.dart';
import '../../core/routes/app_routes.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Map<String, dynamic>? arguments;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.arguments,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      index: currentIndex,
      height: 60.0,
      items: const <Widget>[
        Icon(Icons.home_filled, size: 30, color: Colors.white),
        Icon(Icons.update_outlined, size: 30, color: Colors.white),
        Icon(Icons.person, size: 30, color: Colors.white),
      ],
      color: primaryColor,
      buttonBackgroundColor: primaryColor,
      backgroundColor: Colors.transparent,
      animationCurve: Curves.easeInOutCubic,
      animationDuration: const Duration(milliseconds: 500),
      onTap: (index) {
        onTap(index);
        _handleNavigation(context, index);
      },
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.pushNamed(context, AppRoutes.home);
        });
        break;
      case 1:
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.pushNamed(context, AppRoutes.employeeCheckinCheckout);
        });
        break;
      case 2:
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.pushNamed(
            context,
            AppRoutes.employeesForm,
            arguments: arguments,
          );
        });
        break;
    }
  }
}