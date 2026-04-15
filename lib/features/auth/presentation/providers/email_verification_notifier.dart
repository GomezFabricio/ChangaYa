import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:changaya/features/auth/presentation/providers/auth_providers.dart';

part 'email_verification_notifier.g.dart';

/// Estado del notifier de verificación de email.
class EmailVerificationState {
  const EmailVerificationState({
    this.resendCooldown = 0,
    this.isResending = false,
    this.canResend = true,
    this.lastError,
  });

  /// Segundos restantes antes de poder reenviar (0 = puede reenviar).
  final int resendCooldown;

  /// True mientras el envío está en progreso.
  final bool isResending;

  /// True cuando el cooldown expiró y se puede reenviar.
  final bool canResend;

  /// Último error ocurrido, null si no hay error.
  final Object? lastError;

  EmailVerificationState copyWith({
    int? resendCooldown,
    bool? isResending,
    bool? canResend,
    Object? lastError,
  }) {
    return EmailVerificationState(
      resendCooldown: resendCooldown ?? this.resendCooldown,
      isResending: isResending ?? this.isResending,
      canResend: canResend ?? this.canResend,
      lastError: lastError,
    );
  }
}

/// Notifier para manejar el envío de email de verificación con cooldown de 60s.
///
/// Patrón ADR-D04: limpiar Timer con `ref.onDispose()`.
@riverpod
class EmailVerificationNotifier extends _$EmailVerificationNotifier {
  static const int _cooldownSeconds = 60;
  Timer? _cooldownTimer;

  @override
  EmailVerificationState build() {
    ref.onDispose(() {
      _cooldownTimer?.cancel();
    });
    return const EmailVerificationState();
  }

  /// Envía el email de verificación al usuario actual.
  ///
  /// Si el envío es exitoso, inicia el cooldown de 60 segundos.
  /// Durante el cooldown, [canResend] es false y [resendCooldown] cuenta regresiva.
  Future<void> sendVerificationEmail() async {
    if (!state.canResend || state.isResending) return;

    state = state.copyWith(isResending: true, lastError: null);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.sendEmailVerification();
      _startCooldown();
    } catch (e) {
      state = state.copyWith(
        isResending: false,
        lastError: e,
      );
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();

    state = state.copyWith(
      isResending: false,
      canResend: false,
      resendCooldown: _cooldownSeconds,
    );

    _cooldownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        final newCooldown = state.resendCooldown - 1;
        if (newCooldown <= 0) {
          timer.cancel();
          state = state.copyWith(
            resendCooldown: 0,
            canResend: true,
          );
        } else {
          state = state.copyWith(resendCooldown: newCooldown);
        }
      },
    );
  }
}
