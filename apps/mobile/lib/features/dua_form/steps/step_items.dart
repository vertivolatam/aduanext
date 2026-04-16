/// Step 3: Items — Multi-item list with RIMM classifier drawer.
///
/// Emits `notifier.addItem / updateItem / removeItem` calls on the
/// `duaFormProvider`. Opening the classifier drawer is delegated to
/// the parent page via a callback (so the drawer stays a Scaffold
/// concern — not a form-step concern).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/aduanext_theme.dart';
import '../dua_form_notifier.dart';
import '../dua_form_state.dart';
import '../widgets/item_row.dart';

class StepItems extends ConsumerWidget {
  /// Opens the classifier drawer seeded with [description] and
  /// resolves with the confirmed HS code (or null on cancel).
  ///
  /// The page owns the `endDrawer` slot and this callback; passing
  /// it in keeps [StepItems] purely data-driven for tests.
  final Future<String?> Function(String description)? onRequestClassify;

  const StepItems({super.key, this.onRequestClassify});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(duaFormProvider);
    final notifier = ref.read(duaFormProvider.notifier);

    final totalFob = draft.items.fold<double>(
      0,
      (sum, i) => sum + ((i.quantity ?? 0) * (i.fobAmount ?? 0)),
    );
    final totalMass = draft.items.fold<double>(
      0,
      (sum, i) => sum + (i.grossMassKg ?? 0),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Items',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Agrega cada linea comercial. Cada item debe tener '
                      'descripcion, HS code (RIMM) y valor unitario.',
                      style:
                          TextStyle(color: AduaNextTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  notifier.addItem(const DuaDraftLineItem());
                },
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Agregar item'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (draft.items.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AduaNextTheme.surfaceCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AduaNextTheme.borderSubtle),
              ),
              child: const Column(
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 32, color: AduaNextTheme.textSecondary),
                  SizedBox(height: 8),
                  Text(
                    'Sin items. Pulsa "Agregar item" para empezar.',
                    style: TextStyle(color: AduaNextTheme.textSecondary),
                  ),
                ],
              ),
            )
          else
            for (var i = 0; i < draft.items.length; i++)
              ItemRow(
                key: ValueKey('item-$i'),
                index: i,
                item: draft.items[i],
                onRequestClassify: onRequestClassify,
                onChanged: (next) => notifier.updateItem(i, next),
                onRemove: () => notifier.removeItem(i),
              ),
          if (draft.items.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Totals(totalFob: totalFob, totalMass: totalMass),
          ],
        ],
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  final double totalFob;
  final double totalMass;

  const _Totals({required this.totalFob, required this.totalMass});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AduaNextTheme.surfacePanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AduaNextTheme.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TotalCell(
              label: 'MASA BRUTA TOTAL (kg)',
              value: totalMass.toStringAsFixed(2),
            ),
          ),
          Expanded(
            child: _TotalCell(
              label: 'VALOR FOB TOTAL',
              value: totalFob.toStringAsFixed(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalCell extends StatelessWidget {
  final String label;
  final String value;
  const _TotalCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
            color: AduaNextTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
