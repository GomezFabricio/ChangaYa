import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:changaya/features/auth/domain/user.dart';
import 'package:changaya/features/auth/presentation/providers/auth_providers.dart';
import 'package:changaya/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:changaya/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:changaya/features/auth/presentation/screens/login_screen.dart';
import 'package:changaya/features/auth/presentation/screens/register_screen.dart';
import 'package:changaya/features/profile/presentation/providers/profile_providers.dart';
import 'package:changaya/features/profile/presentation/screens/complete_profile_screen.dart';

// ---------------------------------------------------------------------------
// Rutas públicas — accesibles sin autenticación
// ---------------------------------------------------------------------------
const _publicRoutes = {'/login', '/register', '/forgot-password'};

// ---------------------------------------------------------------------------
// resolveRedirect — función pura exportada para unit testing (ADR-D02)
// ---------------------------------------------------------------------------

/// Resuelve el redirect según el estado del usuario.
///
/// Parámetros:
/// - [user]: usuario autenticado o null si no hay sesión
/// - [emailVerified]: si el email fue verificado
/// - [onboardingComplete]: si el onboarding (P-08) fue completado
/// - [location]: ruta actual del usuario
///
/// Retorna la ruta destino del redirect, o null si no se debe redirigir.
///
/// Cascade de evaluación (ADR-D02):
/// 1. Si no hay usuario → rutas públicas = null, resto → /login
/// 2. Si hay usuario en ruta pública → /home
/// 3. Si email no verificado → /verify-email (excepto si ya está ahí)
/// 4. Si onboarding incompleto → /complete-profile (excepto si ya está ahí)
/// 5. Sin cambio → null
String? resolveRedirect({
  required User? user,
  required bool emailVerified,
  required bool onboardingComplete,
  required String location,
}) {
  final isPublic = _publicRoutes.contains(location);

  // 1. Sin autenticación
  if (user == null) {
    return isPublic ? null : '/login';
  }

  // 2. Autenticado intentando acceder a ruta pública → evaluar estado completo
  //
  // Antes retornaba '/home' ciegamente, lo que causaba un flash visual:
  // /register → /home → /verify-email en cascadas rápidas. Ahora evaluamos
  // emailVerified y onboardingComplete acá mismo para ir al destino correcto
  // en un solo redirect. Ver docs/troubleshooting.md (flash de home).
  if (isPublic) {
    if (!emailVerified) return '/verify-email';
    if (!onboardingComplete) return '/complete-profile';
    return '/home';
  }

  // 3. Email no verificado
  if (!emailVerified) {
    if (location == '/verify-email') return null;
    return '/verify-email';
  }

  // 4. Onboarding incompleto
  if (!onboardingComplete) {
    if (location == '/complete-profile') return null;
    return '/complete-profile';
  }

  // 5. Usuario con estado completo pero parado en una pantalla de onboarding
  // (por ejemplo: login → redirect puso /complete-profile antes que cargara
  // el profile, después el stream emite onboardingComplete=true y el user
  // queda atascado). Forzamos ir a /home.
  if (location == '/verify-email' || location == '/complete-profile') {
    return '/home';
  }

  // 6. Todo OK — sin redirect
  return null;
}

// ---------------------------------------------------------------------------
// _AuthChangeNotifier — bridge Riverpod → GoRouter refreshListenable
// ---------------------------------------------------------------------------

/// Puente entre el stream de auth de Riverpod y [GoRouter.refreshListenable].
///
/// GoRouter escucha cambios en este [ChangeNotifier] para re-evaluar redirects.
/// Se suscribe al [authStateChangesProvider] y notifica cada vez que cambia.
class AuthChangeNotifier extends ChangeNotifier {
  AuthChangeNotifier(this._ref) {
    _ref.listen(
      authStateChangesProvider,
      (_, __) => notifyListeners(),
    );
    _ref.listen(
      userProfileProvider,
      (_, __) => notifyListeners(),
    );
  }

  final WidgetRef _ref;
}

// ---------------------------------------------------------------------------
// buildRouter — factory del GoRouter con guardias completos
// ---------------------------------------------------------------------------

/// Construye el [GoRouter] con todas las rutas y la lógica de redirect.
///
/// Recibe [ref] para acceder a los providers de Riverpod desde el redirect callback.
GoRouter buildRouter(WidgetRef ref) {
  final authChangeNotifier = AuthChangeNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authChangeNotifier,
    redirect: (context, state) {
      final authAsync = ref.read(authStateChangesProvider);
      final user = authAsync.value;

      final profile = user != null ? ref.read(userProfileProvider).value : null;

      return resolveRedirect(
        user: user,
        emailVerified: user?.emailVerified ?? false,
        onboardingComplete: profile?.onboardingComplete ?? false,
        location: state.uri.path,
      );
    },
    routes: [
      // Rutas públicas
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Rutas protegidas — requieren auth
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      GoRoute(
        path: '/complete-profile',
        builder: (context, state) => const CompleteProfileScreen(),
      ),

      // Home — placeholder hasta que se implemente el feature de home
      GoRoute(
        path: '/home',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text(
              'Home — próximamente',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
      ),
    ],
  );
}
