import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/declarations/exports_page.dart';
import '../features/onboarding/agent_onboarding_flow.dart';
import '../features/onboarding/welcome_page.dart';
import '../shared/ui/templates/dashboard_layout.dart';

final router = GoRouter(
  initialLocation: '/exports',
  routes: [
    // Onboarding routes — no dashboard shell (the wizard is full-bleed).
    GoRoute(
      path: '/onboarding',
      builder: (_, _) => const WelcomePage(),
    ),
    GoRoute(
      path: '/onboarding/agent',
      builder: (_, _) => const AgentOnboardingFlow(),
    ),

    // Authenticated app — dashboard shell.
    ShellRoute(
      builder: (context, state, child) {
        return DashboardLayout(
          currentRoute: state.uri.path,
          onNavigate: (route) => context.go(route),
          child: child,
        );
      },
      routes: [
        GoRoute(path: '/exports', builder: (_, _) => const ExportsPage()),
        GoRoute(
          path: '/imports',
          builder: (_, _) => _Placeholder('Importaciones'),
        ),
        GoRoute(
          path: '/rectifications',
          builder: (_, _) => _Placeholder('Rectificaciones'),
        ),
        GoRoute(
          path: '/drafts',
          builder: (_, _) => _Placeholder('Borradores'),
        ),
        GoRoute(
          path: '/classify',
          builder: (_, _) => _Placeholder('Clasificador RIMM'),
        ),
        GoRoute(
          path: '/risk',
          builder: (_, _) => _Placeholder('Risk Score'),
        ),
        GoRoute(
          path: '/exchange',
          builder: (_, _) => _Placeholder('Tipo de Cambio'),
        ),
        GoRoute(
          path: '/agents',
          builder: (_, _) => _Placeholder('Mis Agentes'),
        ),
        GoRoute(
          path: '/sourcers',
          builder: (_, _) => _Placeholder('Vetted Sourcers'),
        ),
        GoRoute(
          path: '/audit',
          builder: (_, _) => _Placeholder('Audit Trail'),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, _) => _Placeholder('Configuracion'),
        ),
      ],
    ),
  ],
);

class _Placeholder extends StatelessWidget {
  final String title;
  const _Placeholder(this.title);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
