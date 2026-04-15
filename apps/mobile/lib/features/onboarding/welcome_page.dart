/// Welcome / role-picker landing page — SOP-A01 entry point.
///
/// Three choices:
///   * Agente Aduanero (P02 — freelance agent; full VRTV-59 flow)
///   * Importador Pyme (P03 — pyme; placeholder, separate issue)
///   * Estudiante (universidad sandbox; placeholder, separate issue)
///
/// Only the "Agente Aduanero" button is wired in this MVP — the other
/// two navigate to a `ComingSoon` placeholder so the flywheel story is
/// visible in the UI even before those flows ship.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Bienvenido a AduaNext',
                  style: theme.textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Selecciona tu rol para comenzar la configuracion.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                _RoleCard(
                  title: 'Agente Aduanero',
                  subtitle:
                      'Freelance o supervisor de agencia. Prepara y firma DUAs.',
                  icon: Icons.badge_outlined,
                  enabled: true,
                  onTap: () => context.go('/onboarding/agent'),
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  title: 'Importador / Pyme',
                  subtitle:
                      'Contrata un agente autorizado y monitorea tus DUAs.',
                  icon: Icons.local_shipping_outlined,
                  enabled: false,
                  onTap: () => _comingSoon(context, 'Onboarding de pyme'),
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  title: 'Estudiante / Universidad',
                  subtitle:
                      'Sandbox educativo. Certificate sin riesgo.',
                  icon: Icons.school_outlined,
                  enabled: false,
                  onTap: () => _comingSoon(context, 'Sandbox educativo'),
                ),
                const SizedBox(height: 24),
                Text(
                  'Ya tienes cuenta? Inicia sesion.',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — disponible en una iteracion siguiente.')),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: enabled ? 2 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 40, color: theme.colorScheme.primary),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(title, style: theme.textTheme.titleLarge),
                        if (!enabled)
                          Chip(
                            label: const Text('Proximamente'),
                            padding: EdgeInsets.zero,
                            labelStyle: theme.textTheme.labelSmall,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
