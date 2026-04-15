import 'package:flutter/material.dart';

/// Muestra un [SnackBar] de error con el [message] provisto.
///
/// Usa [ScaffoldMessenger] para mostrar la notificación en el
/// Scaffold más cercano en el árbol de widgets.
void showErrorSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.error,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
