import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/classifier/classifier_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/dashboard/dua_detail_page.dart';
import '../features/dua_form/dua_form_page.dart';
import '../features/onboarding/agent_onboarding_flow.dart';
import '../features/onboarding/welcome_page.dart';
import '../shared/ui/templates/dashboard_layout.dart';

/// Root GoRouter configuration.
///
/// Authenticated routes ship inside a [ShellRoute] so the rail + panel
/// chrome stays mounted across navigation. The onboarding wizard is
/// deliberately outside the shell — the wizard is full-bleed.
///
/// `/exports` is kept as a redirect to `/dashboard` so any in-flight
/// VRTV-39 deep-links (bookmarks, onboarding deep links) keep working
/// through the rollout.
final router = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (_, _) => const WelcomePage(),
    ),
    GoRoute(
      path: '/onboarding/agent',
      builder: (_, _) => const AgentOnboardingFlow(),
    ),

    // Legacy route — redirect before the DashboardLayout evaluates.
    GoRoute(
      path: '/exports',
      redirect: (_, _) => '/dashboard',
    ),

    ShellRoute(
      builder: (context, state, child) {
        return DashboardLayout(
          currentRoute: state.uri.path,
          onNavigate: (route) => context.go(route),
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (_, _) => const DashboardPage(),
        ),
        GoRoute(
          path: '/dispatches/:id',
          builder: (_, state) => DuaDetailPage(
            declarationId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/dua-form/new',
          builder: (_, _) => const DuaFormPage(),
        ),
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
          builder: (_, _) => const ClassifierPage(),
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
