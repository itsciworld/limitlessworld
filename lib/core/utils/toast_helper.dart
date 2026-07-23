import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../app_tost/app_tost.dart';
import '../router/navigator_key.dart';

/// App-wide toasts.
///
/// These render through [showAppToast]'s overlay rather than the platform
/// toast, because the native Android toast only offers ~2s (SHORT) or ~3.5s
/// (LONG) — it cannot be held for exactly [duration].
class AppToast {
  AppToast._();

  /// How long every toast stays on screen.
  static const Duration duration = Duration(seconds: 3);

  static void showSuccess(String message, {String title = 'Success'}) =>
      _show(title, message, ToastType.success);

  static void showError(String message, {String title = 'Error'}) =>
      _show(title, message, ToastType.error);

  static void showWarning(String message, {String title = 'Warning'}) =>
      _show(title, message, ToastType.warning);

  static void showInfo(String message, {String title = 'Info'}) =>
      _show(title, message, ToastType.info);

  /// Neutral toast, used where the message speaks for itself.
  static void showToast(String message, {String title = 'Info'}) =>
      _show(title, message, ToastType.info);

  static void _show(String title, String message, ToastType type) {
    if (message.trim().isEmpty) return;

    // The navigator's own overlay, taken from its state — an ancestor lookup
    // from the navigator's context would miss it.
    final overlay = rootNavigatorKey.currentState?.overlay;
    if (overlay != null && overlay.mounted) {
      showAppToast(
        overlayState: overlay,
        title: title,
        subtitle: message,
        type: type,
        duration: duration,
      );
      return;
    }

    // No navigator yet (very early startup, or a toast fired after teardown).
    // Fall back to the platform toast so the message is not simply lost.
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: duration.inSeconds,
      backgroundColor: const Color(0xFF1E3A5F),
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }
}
