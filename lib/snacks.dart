import 'package:flutter/material.dart';

// Displays an error message using the snackbar.

void displayError(BuildContext context, String msg) {
  if (context.mounted) {
    final snackBar = SnackBar(
      backgroundColor: Colors.red,
      content: Row(children: [
        const Icon(Icons.error, color: Colors.white),
        Text(msg, style: const TextStyle(color: Colors.yellow))
      ]),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
