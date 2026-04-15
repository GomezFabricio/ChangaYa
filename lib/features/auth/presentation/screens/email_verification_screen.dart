import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:changaya/core/widgets/error_snackbar.dart';
import 'package:changaya/features/auth/presentation/providers/auth_providers.dart';
import 'package:changaya/features/auth/presentation/providers/email_verification_notifier.dart';

// The generated provider name for EmailVerificationNotifier is emailVerificationProvider
// (see email_verification_notifier.g.dart).

/// Pantalla de verificación de email (P-06).
///
/// Muestra el email al que se envió el enlace de verificación.
/// Permite reenviar el email con cooldown de 60 segundos.
/// Polling automático via authStateChanges para detectar verificación.
class EmailVerificationScreen extends ConsumerWidget {
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateChangesProvider);
    final verificationState = ref.watch(emailVerificationProvider);
    final notifier = ref.read(emailVerificationProvider.notifier);

    final email = authAsync.value?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificá tu email'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Icon(
                Icons.mark_email_unread_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Revisá tu bandeja de entrada',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Te enviamos un email de verificación a:',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                email,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (verificationState.canResend)
                ElevatedButton(
                  onPressed: verificationState.isResending
                      ? null
                      : () async {
                          await notifier.sendVerificationEmail();
                          if (context.mounted &&
                              verificationState.lastError != null) {
                            showErrorSnackbar(
                              context,
                              'Error al reenviar. Intentá más tarde.',
                            );
                          }
                        },
                  child: const Text('Reenviar email'),
                )
              else
                ElevatedButton(
                  onPressed: null,
                  child: Text(
                    'Reenviar en ${verificationState.resendCooldown}s',
                  ),
                ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () async {
                  // Patrón híbrido (ver docs/troubleshooting.md):
                  //   1. Reload: trae el estado fresco del user desde Firebase.
                  //   2. Verificación directa + nav imperativa: no dependemos de
                  //      que userChanges() emita (puede no hacerlo en Android tras
                  //      reload()). GoRouter redirect decide el destino final.
                  final repo = ref.read(authRepositoryProvider);
                  await repo.reloadUser();
                  if (!context.mounted) return;
                  final user = repo.currentUser;
                  if (user != null && user.emailVerified) {
                    context.go('/complete-profile');
                  } else {
                    showErrorSnackbar(
                      context,
                      'Aún no detectamos tu verificación. Revisá el email.',
                    );
                  }
                },
                child: const Text('Ya verifiqué mi email'),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () async {
                  final repo = ref.read(authRepositoryProvider);
                  await repo.signOut();
                },
                child: const Text('Cambiar cuenta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
