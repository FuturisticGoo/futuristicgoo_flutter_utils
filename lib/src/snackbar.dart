import 'package:flutter/material.dart';

void showSnackBar(BuildContext context, {required String text}) async {
  ScaffoldMessenger.of(context).clearSnackBars();
  final controller = ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(text)));
  await Future.delayed(Durations.long4);
  try {
    controller.close();
  } on AssertionError {
    // Ignore, it happens when closing an already closed snackbar
  }
}
