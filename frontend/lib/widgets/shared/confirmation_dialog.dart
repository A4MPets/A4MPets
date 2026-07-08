import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';

Future<bool> showAppConfirmationDialog({
  required BuildContext context,
  required bool isDarkMode,
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: AppPalette.dialogBackground(isDarkMode),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppPalette.border(isDarkMode)),
        ),
        title: Text(
          title,
          style: TextStyle(color: AppPalette.dialogTitle(isDarkMode), fontWeight: FontWeight.w700),
        ),
        content: Text(message, style: TextStyle(color: AppPalette.dialogBody(isDarkMode))),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppPalette.dialogCancel(isDarkMode), fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              confirmLabel,
              style: const TextStyle(color: AppPalette.dangerRed, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
