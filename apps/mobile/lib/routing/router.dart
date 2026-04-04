import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../shared/ui/templates/dashboard_layout.dart';
import '../features/declarations/exports_page.dart';

final router = GoRouter(
  initialLocation: '/exports',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return DashboardLayout(
          currentRoute: state.uri.path,
          onNavigate: (route) => context.go(route),
          child: child,
        );
      },
      routes: [
        GoRoute(path: '/exports', builder: (_, __) => const ExportsPage()),
        GoRoute(path: '/imports', builder: (_, __) => _Placeholder('Importaciones')),
        GoRoute(path: '/rectifications', builder: (_, __) => _Placeholder('Rectificaciones')),
        GoRoute(path: '/drafts', builder: (_, __) => _Placeholder('Borradores')),
        GoRoute(path: '/classify', builder: (_, __) => _Placeholder('Clasificador RIMM')),
        GoRoute(path: '/risk', builder: (_, __) => _Placeholder('Risk Score')),
        GoRoute(path: '/exchange', builder: (_, __) => _Placeholder('Tipo de Cambio')),
        GoRoute(path: '/agents', builder: (_, __) => _Placeholder('Mis Agentes')),
        GoRoute(path: '/sourcers', builder: (_, __) => _Placeholder('Vetted Sourcers')),
        GoRoute(path: '/audit', builder: (_, __) => _Placeholder('Audit Trail')),
        GoRoute(path: '/settings', builder: (_, __) => _Placeholder('Configuracion')),
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
