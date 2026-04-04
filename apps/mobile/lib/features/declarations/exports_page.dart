import 'package:flutter/material.dart';
import '../../shared/theme/aduanext_theme.dart';

/// Placeholder page for Exports list.
/// Will be replaced by full implementation in VRTV-45.
class ExportsPage extends StatelessWidget {
  const ExportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Exportaciones', style: Theme.of(context).textTheme.headlineMedium),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Nueva DUA'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tabs
          DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    Tab(text: 'Lista'),
                    Tab(text: 'Timeline'),
                    Tab(text: 'Kanban'),
                  ],
                ),
                const SizedBox(height: 16),
                // Placeholder DUA cards
                _DuaCard(
                  number: 'DUA-2026-0891',
                  description: 'Cafe verde SHB — FOB \$4,198 — Aduana Santamaria',
                  status: 'Levante',
                  statusColor: AduaNextTheme.statusLevante,
                  statusBg: AduaNextTheme.statusLevanteBg,
                  time: '2h',
                ),
                _DuaCard(
                  number: 'DUA-2026-0892',
                  description: 'Cajas de carton corrugado — CIP \$760,995 — Aduana Caldera',
                  status: 'Validando',
                  statusColor: AduaNextTheme.statusValidando,
                  statusBg: AduaNextTheme.statusValidandoBg,
                  time: '45m',
                ),
                _DuaCard(
                  number: 'DUA-2026-0893',
                  description: 'LED grow lights horticultura — FCA \$10,000 — Shenzhen → Heredia',
                  status: 'Borrador',
                  statusColor: AduaNextTheme.statusBorrador,
                  statusBg: AduaNextTheme.statusBorradorBg,
                  time: '',
                  highlighted: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DuaCard extends StatelessWidget {
  final String number;
  final String description;
  final String status;
  final Color statusColor;
  final Color statusBg;
  final String time;
  final bool highlighted;

  const _DuaCard({
    required this.number,
    required this.description,
    required this.status,
    required this.statusColor,
    required this.statusBg,
    required this.time,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AduaNextTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlighted ? AduaNextTheme.primary : AduaNextTheme.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(number, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AduaNextTheme.textPrimary)),
                const SizedBox(height: 3),
                Text(description, style: const TextStyle(fontSize: 11, color: AduaNextTheme.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.5)),
            ),
            child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
          if (time.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(time, style: const TextStyle(fontSize: 11, color: AduaNextTheme.textSecondary)),
          ],
        ],
      ),
    );
  }
}
