import 'package:aduanext_ui/aduanext_ui.dart';
import 'package:flutter/material.dart';

/// Showcase del Design System de AduaNext — tokens de color y tipografía
/// reales de `AduaNextTheme` (dark theme, fuente Ubuntu).
class DesignSystemShowcase extends StatelessWidget {
  const DesignSystemShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    const colorGroups = <String, Map<String, Color>>{
      'Superficies': {
        'surfaceRail': AduaNextTheme.surfaceRail,
        'surfacePanel': AduaNextTheme.surfacePanel,
        'surfaceContent': AduaNextTheme.surfaceContent,
        'surfaceCard': AduaNextTheme.surfaceCard,
        'borderSubtle': AduaNextTheme.borderSubtle,
      },
      'Primario y texto': {
        'primary': AduaNextTheme.primary,
        'primaryLight': AduaNextTheme.primaryLight,
        'textPrimary': AduaNextTheme.textPrimary,
        'textSecondary': AduaNextTheme.textSecondary,
      },
      'Estados (semáforo)': {
        'statusLevante': AduaNextTheme.statusLevante,
        'statusValidando': AduaNextTheme.statusValidando,
        'statusRechazada': AduaNextTheme.statusRechazada,
      },
    };

    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final group in colorGroups.entries) ...[
          Text(group.key, style: textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final entry in group.value.entries)
                _ColorSwatchTile(label: entry.key, color: entry.value),
            ],
          ),
          const SizedBox(height: 24),
        ],
        Text('Tipografía (Ubuntu)', style: textTheme.titleLarge),
        const SizedBox(height: 12),
        for (final sample in {
          'Headline Large': textTheme.headlineLarge,
          'Title Large': textTheme.titleLarge,
          'Body Large': textTheme.bodyLarge,
          'Body Medium': textTheme.bodyMedium,
          'Label Small': textTheme.labelSmall,
        }.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(sample.key, style: sample.value),
          ),
      ],
    );
  }
}

class _ColorSwatchTile extends StatelessWidget {
  final String label;
  final Color color;

  const _ColorSwatchTile({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 110,
          height: 64,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        Text(
          '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}
