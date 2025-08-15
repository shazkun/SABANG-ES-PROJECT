import 'package:flutter/material.dart';

class CustomSnackBar {
  static bool _isShowing = false;

  static void show(
    BuildContext context,
    String message, {
    bool isSuccess = true,
    Color? backgroundColor,
    Color? textColor,
    Color? iconColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 2),
  }) {
    if (_isShowing) {
      ScaffoldMessenger.of(context).clearSnackBars();
    }

    _isShowing = true;

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            icon ?? (isSuccess ? Icons.check_circle : Icons.error),
            color: iconColor ?? Colors.white,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: textColor ?? Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      backgroundColor:
          backgroundColor ??
          (isSuccess ? Colors.green.shade600 : Colors.red.shade600),
      behavior: SnackBarBehavior.fixed, // ✅ always bottom
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ), // flat edges
      duration: duration,
      elevation: 6,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar).closed.then((_) {
      _isShowing = false;
    });
  }
}
