import 'package:flutter/material.dart';

/// [TextFormField] con estilo consistente para toda la app ChangaYa.
///
/// Acepta [label], [hint], [validator] y [obscureText].
/// El decorado usa el [InputDecorationTheme] definido en [AppTheme].
class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    this.hint,
    this.validator,
    this.obscureText = false,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.suffixIcon,
    this.autofillHints,
    super.key,
  });

  /// Etiqueta flotante del campo.
  final String label;

  /// Texto de ayuda dentro del campo cuando está vacío.
  final String? hint;

  /// Función de validación. Retorna mensaje de error o null si válido.
  final FormFieldValidator<String>? validator;

  /// Si true, el texto se oculta (para contraseñas).
  final bool obscureText;

  /// Controlador externo opcional.
  final TextEditingController? controller;

  /// Tipo de teclado.
  final TextInputType? keyboardType;

  /// Acción del botón de acción del teclado.
  final TextInputAction? textInputAction;

  /// Callback cuando el texto cambia.
  final ValueChanged<String>? onChanged;

  /// Widget al final del campo (e.g. ícono de visibilidad).
  final Widget? suffixIcon;

  /// Autofill hints para accesibilidad y gestores de contraseñas.
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      autofillHints: autofillHints,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
