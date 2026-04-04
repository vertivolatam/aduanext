import 'package:flutter/material.dart';
import '../../theme/aduanext_theme.dart';

/// Rail sidebar (56px) with icon buttons for each section.
/// Highlights active section. Shows notification badge.
class SidebarRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool hasNotification;

  const SidebarRail({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    this.hasNotification = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      color: AduaNextTheme.surfaceRail,
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Logo
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AduaNextTheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
          // Section icons
          _RailIcon(icon: '📋', label: 'Operaciones', index: 0, selected: selectedIndex == 0, onTap: () => onSelected(0), hasNotification: hasNotification),
          _RailIcon(icon: '🔍', label: 'Herramientas', index: 1, selected: selectedIndex == 1, onTap: () => onSelected(1)),
          _RailIcon(icon: '🏪', label: 'Marketplace', index: 2, selected: selectedIndex == 2, onTap: () => onSelected(2)),
          const Spacer(),
          _RailIcon(icon: '⚙️', label: 'Sistema', index: 3, selected: selectedIndex == 3, onTap: () => onSelected(3)),
          // Avatar
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AduaNextTheme.surfaceCard,
              shape: BoxShape.circle,
              border: Border.all(color: AduaNextTheme.primary, width: 2),
            ),
            child: const Center(
              child: Text('AP', style: TextStyle(color: AduaNextTheme.textSecondary, fontSize: 12)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _RailIcon extends StatelessWidget {
  final String icon;
  final String label;
  final int index;
  final bool selected;
  final VoidCallback onTap;
  final bool hasNotification;

  const _RailIcon({
    required this.icon,
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
    this.hasNotification = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1A1A30) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
              if (hasNotification)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AduaNextTheme.statusRechazada,
                      shape: BoxShape.circle,
                      border: Border.all(color: AduaNextTheme.surfaceRail, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
