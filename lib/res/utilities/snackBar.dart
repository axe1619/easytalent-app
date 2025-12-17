import 'package:flutter/material.dart';
import '../consts/app_colors.dart';

class AppSnackBar {
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: primaryColor,
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: primaryColor,
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showConnectivityError(BuildContext context, {
    required VoidCallback onClose,
    required Future<bool> Function() checkConnection,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: primaryColor,
        content: const Text(
          'Please check your internet connectivity',
          style: TextStyle(color: Colors.white),
        ),
        action: SnackBarAction(
          backgroundColor: primaryColor,
          label: 'close',
          textColor: Colors.white,
          onPressed: onClose,
        ),
        duration: const Duration(hours: 1),
      ),
    );
  }
}
