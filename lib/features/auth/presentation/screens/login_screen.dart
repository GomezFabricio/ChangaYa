import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:changaya/core/widgets/error_snackbar.dart';
import 'package:changaya/core/widgets/loading_button.dart';
import 'package:changaya/features/auth/domain/auth_failure.dart';
import 'package:changaya/features/auth/presentation/providers/auth_providers.dart';

/// Keys para los campos del form — usadas en widget tests.
const loginEmailFieldKey = Key('login_email_field');
const loginPasswordFieldKey = Key('login_password_field');

/// Pantalla de inicio de sesión (P-04).
///
/// Permite login con email/contraseña o con Google OAuth.
/// Navega a home (o verify-email) según el estado post-login.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _messageForFailure(AuthFailure failure) {
    return failure.message ?? 'Ocurrió un error inesperado.';
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // GoRouter redirect se encarga de la navegación
    } on AuthFailure catch (e) {
      if (mounted) {
        showErrorSnackbar(context, _messageForFailure(e));
      }
    } catch (_) {
      if (mounted) {
        showErrorSnackbar(context, 'Ocurrió un error inesperado.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signInWithGoogle();
    } on AuthFailure catch (e) {
      if (mounted) {
        showErrorSnackbar(context, _messageForFailure(e));
      }
    } catch (_) {
      if (mounted) {
        showErrorSnackbar(context, 'Ocurrió un error inesperado.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                Text(
                  'ChangaYa',
                  style: theme.textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Iniciá sesión para continuar',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextFormField(
                  key: loginEmailFieldKey,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'tu@email.com',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresá tu email';
                    }
                    final emailRegex = RegExp(
                      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
                    );
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Ingresá un email válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: loginPasswordFieldKey,
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _signIn(),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    hintText: '••••••',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(
                          () => _obscurePassword = !_obscurePassword,
                        );
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresá tu contraseña';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
                ),
                const SizedBox(height: 16),
                LoadingButton(
                  onPressed: _isLoading ? null : _signIn,
                  label: 'Iniciar sesión',
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: const Icon(Icons.login),
                  label: const Text('Continuar con Google'),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿No tenés cuenta? ',
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.push('/register'),
                      child: const Text('Registrate'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
