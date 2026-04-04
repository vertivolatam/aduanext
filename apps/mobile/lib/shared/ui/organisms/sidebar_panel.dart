import 'package:flutter/material.dart';
import '../../theme/aduanext_theme.dart';

/// Expandable panel (210px) with grouped navigation items.
/// Shows section headers (OPERACIONES, HERRAMIENTAS, MARKETPLACE).
class SidebarPanel extends StatelessWidget {
  final int selectedSection;
  final String? selectedItem;
  final ValueChanged<String> onItemSelected;

  const SidebarPanel({
    super.key,
    required this.selectedSection,
    this.selectedItem,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      color: AduaNextTheme.surfacePanel,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (selectedSection == 0) ..._operaciones(),
          if (selectedSection == 1) ..._herramientas(),
          if (selectedSection == 2) ..._marketplace(),
          if (selectedSection == 3) ..._sistema(),
        ],
      ),
    );
  }

  List<Widget> _operaciones() => [
        _SectionHeader(label: 'Operaciones'),
        _PanelItem(label: 'Exportaciones', count: 12, id: '/exports', selected: selectedItem == '/exports', onTap: () => onItemSelected('/exports')),
        _PanelItem(label: 'Importaciones', count: 3, id: '/imports', selected: selectedItem == '/imports', onTap: () => onItemSelected('/imports')),
        _PanelItem(label: 'Rectificaciones', id: '/rectifications', selected: selectedItem == '/rectifications', onTap: () => onItemSelected('/rectifications')),
        _PanelItem(label: 'Borradores (5)', id: '/drafts', selected: selectedItem == '/drafts', onTap: () => onItemSelected('/drafts'), dimmed: true),
      ];

  List<Widget> _herramientas() => [
        _SectionHeader(label: 'Herramientas'),
        _PanelItem(label: 'Clasificador RIMM', id: '/classify', selected: selectedItem == '/classify', onTap: () => onItemSelected('/classify')),
        _PanelItem(label: 'Risk Score', id: '/risk', selected: selectedItem == '/risk', onTap: () => onItemSelected('/risk')),
        _PanelItem(label: 'Tipo de Cambio', id: '/exchange', selected: selectedItem == '/exchange', onTap: () => onItemSelected('/exchange')),
      ];

  List<Widget> _marketplace() => [
        _SectionHeader(label: 'Marketplace'),
        _PanelItem(label: 'Mis Agentes', id: '/agents', selected: selectedItem == '/agents', onTap: () => onItemSelected('/agents')),
        _PanelItem(label: 'Vetted Sourcers', id: '/sourcers', selected: selectedItem == '/sourcers', onTap: () => onItemSelected('/sourcers')),
      ];

  List<Widget> _sistema() => [
        _SectionHeader(label: 'Sistema'),
        _PanelItem(label: 'Audit Trail', id: '/audit', selected: selectedItem == '/audit', onTap: () => onItemSelected('/audit')),
        _PanelItem(label: 'Configuracion', id: '/settings', selected: selectedItem == '/settings', onTap: () => onItemSelected('/settings')),
      ];
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AduaNextTheme.primary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _PanelItem extends StatelessWidget {
  final String label;
  final int? count;
  final String id;
  final bool selected;
  final VoidCallback onTap;
  final bool dimmed;

  const _PanelItem({
    required this.label,
    this.count,
    required this.id,
    required this.selected,
    required this.onTap,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A1A30) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: selected ? const Border(left: BorderSide(color: AduaNextTheme.primary, width: 3)) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : dimmed
                          ? AduaNextTheme.textSecondary
                          : AduaNextTheme.textPrimary,
                  fontSize: 12,
                ),
              ),
            ),
            if (count != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? AduaNextTheme.primary : AduaNextTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 9,
                    color: selected ? Colors.white : AduaNextTheme.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
