// test/app/resolve_redirect_test.dart
//
// Tests unitarios para resolveRedirect() — función pura exportada desde routes.dart.
// STRICT TDD: tests escritos ANTES de la implementación.
//
// No instancia GoRouter — testea solo la función pura (ADR-D02).
import 'package:flutter_test/flutter_test.dart';
import 'package:changaya/app/routes.dart';
import 'package:changaya/features/auth/domain/user.dart';

void main() {
  const authenticatedUser = User(
    uid: 'uid-redirect-001',
    email: 'test@example.com',
    emailVerified: true,
    onboardingComplete: true,
    providers: ['password'],
  );

  group('resolveRedirect — usuario no autenticado', () {
    test(
      'should_redirect_to_login_when_user_null_and_accessing_protected_route',
      () {
        final result = resolveRedirect(
          user: null,
          emailVerified: false,
          onboardingComplete: false,
          location: '/home',
        );

        expect(result, equals('/login'));
      },
    );

    test(
      'should_redirect_to_login_when_user_null_and_accessing_complete_profile',
      () {
        final result = resolveRedirect(
          user: null,
          emailVerified: false,
          onboardingComplete: false,
          location: '/complete-profile',
        );

        expect(result, equals('/login'));
      },
    );

    test(
      'should_not_redirect_when_user_null_and_on_login',
      () {
        final result = resolveRedirect(
          user: null,
          emailVerified: false,
          onboardingComplete: false,
          location: '/login',
        );

        expect(result, isNull);
      },
    );

    test(
      'should_not_redirect_when_user_null_and_on_register',
      () {
        final result = resolveRedirect(
          user: null,
          emailVerified: false,
          onboardingComplete: false,
          location: '/register',
        );

        expect(result, isNull);
      },
    );

    test(
      'should_not_redirect_when_user_null_and_on_forgot_password',
      () {
        final result = resolveRedirect(
          user: null,
          emailVerified: false,
          onboardingComplete: false,
          location: '/forgot-password',
        );

        expect(result, isNull);
      },
    );
  });

  group('resolveRedirect — usuario autenticado, email no verificado', () {
    test(
      'should_redirect_to_verify_email_when_email_not_verified_and_going_home',
      () {
        final result = resolveRedirect(
          user: authenticatedUser,
          emailVerified: false,
          onboardingComplete: false,
          location: '/home',
        );

        expect(result, equals('/verify-email'));
      },
    );

    test(
      'should_not_redirect_when_email_not_verified_and_already_on_verify_email',
      () {
        final result = resolveRedirect(
          user: authenticatedUser,
          emailVerified: false,
          onboardingComplete: false,
          location: '/verify-email',
        );

        expect(result, isNull);
      },
    );
  });

  group(
      'resolveRedirect — usuario autenticado, email verificado, onboarding incompleto',
      () {
    test(
      'should_redirect_to_complete_profile_when_onboarding_incomplete',
      () {
        final result = resolveRedirect(
          user: authenticatedUser,
          emailVerified: true,
          onboardingComplete: false,
          location: '/home',
        );

        expect(result, equals('/complete-profile'));
      },
    );

    test(
      'should_not_redirect_when_onboarding_incomplete_and_already_on_complete_profile',
      () {
        final result = resolveRedirect(
          user: authenticatedUser,
          emailVerified: true,
          onboardingComplete: false,
          location: '/complete-profile',
        );

        expect(result, isNull);
      },
    );
  });

  group('resolveRedirect — usuario completamente onboarded', () {
    test(
      'should_not_redirect_when_user_fully_authenticated_and_onboarded',
      () {
        final result = resolveRedirect(
          user: authenticatedUser,
          emailVerified: true,
          onboardingComplete: true,
          location: '/home',
        );

        expect(result, isNull);
      },
    );

    test(
      'should_redirect_to_home_when_authenticated_user_visits_login',
      () {
        final result = resolveRedirect(
          user: authenticatedUser,
          emailVerified: true,
          onboardingComplete: true,
          location: '/login',
        );

        expect(result, equals('/home'));
      },
    );

    test(
      'should_redirect_to_home_when_authenticated_user_visits_register',
      () {
        final result = resolveRedirect(
          user: authenticatedUser,
          emailVerified: true,
          onboardingComplete: true,
          location: '/register',
        );

        expect(result, equals('/home'));
      },
    );
  });
}
