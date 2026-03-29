import 'package:flutter/material.dart';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

class SnackbarHelper {
  static void showAwesomeSnackbar(
    BuildContext context, {
    required String title,
    required String message,
    required ContentType contentType,
  }) {
    debugPrint('Snackbar: [$title] $message');
    if (!context.mounted) return;

    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: title,
        message: message,
        contentType: contentType,
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  static void showSuccess(BuildContext context, String title, String message) {
    showAwesomeSnackbar(
      context,
      title: title,
      message: message,
      contentType: ContentType.success,
    );
  }

  static void showError(BuildContext context, String title, String message) {
    showAwesomeSnackbar(
      context,
      title: title,
      message: message,
      contentType: ContentType.failure,
    );
  }

  static void showInfo(BuildContext context, String title, String message) {
    showAwesomeSnackbar(
      context,
      title: title,
      message: message,
      contentType: ContentType.help,
    );
  }
}
