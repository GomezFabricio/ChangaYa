import 'package:flutter/material.dart';

/// ElevatedButton que muestra un [CircularProgressIndicator]
/// cuando [isLoading] es true.
///
/// Deshabilita el botón automáticamente durante la carga.
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    required this.onPressed,
    required this.label,
    this.isLoading = false,
    super.key,
  });

  /// Callback al presionar. Si null o [isLoading] es true, el botón se deshabilita.
  final VoidCallback? onPressed;

  /// Texto del botón.
  final String label;

  /// Si true, muestra CircularProgressIndicator y deshabilita el botón.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
              ),
            )
          : Text(label),
    );
  }
}
