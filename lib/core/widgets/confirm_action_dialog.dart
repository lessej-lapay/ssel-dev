import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<bool> confirmAction({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(message, style: GoogleFonts.inter(height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: destructive ? Colors.red.shade700 : null,
            ),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
