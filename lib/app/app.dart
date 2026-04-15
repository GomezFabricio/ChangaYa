import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:changaya/app/routes.dart';
import 'package:changaya/app/theme.dart';

/// Widget raíz de la aplicación ChangaYa.
///
/// [AppRoot] es un [ConsumerWidget] que construye el [GoRouter]
/// con acceso a Riverpod [Ref], pasándolo a [App].
///
/// El [ProviderScope] se agrega en los main_*.dart, NO acá,
/// para permitir overrides de providers en tests.
class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Construir el router dentro del scope de Riverpod para tener acceso a Ref
    final router = buildRouter(ref);
    return App(router: router);
  }
}

/// Widget de presentación de la aplicación.
///
/// Recibe el [router] como parámetro para permitir inyección desde tests.
class App extends StatelessWidget {
  const App({required this.router, super.key});

  /// GoRouter configurado con todas las rutas y guardias.
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ChangaYa',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
