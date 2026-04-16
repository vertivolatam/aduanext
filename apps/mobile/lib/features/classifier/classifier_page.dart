/// Standalone classifier page for the `/classify` route.
///
/// Shows the classifier drawer inline (full right panel) with a
/// placeholder left content so the agent can exercise the RIMM
/// workflow without a DUA form. Confirmation logs to a SnackBar
/// with the selected HS code — the real `RecordClassificationCommand`
/// wire-up lands with VRTV-38/VRTV-43.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/theme/aduanext_theme.dart';
import 'classifier_drawer.dart';

class ClassifierPage extends ConsumerStatefulWidget {
  const ClassifierPage({super.key});

  @override
  ConsumerState<ClassifierPage> createState() => _ClassifierPageState();
}

class _ClassifierPageState extends ConsumerState<ClassifierPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() => _scaffoldKey.currentState?.openEndDrawer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      endDrawer: ClassifierDrawer(
        contextLabel: 'Clasificación libre',
        onConfirm: (result) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Clasificación seleccionada: ${result.suggestion.hsCode}',
              ),
            ),
          );
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Clasificador RIMM',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Busca sugerencias de HS code con texto completo, AI o código '
              'directo. Toda clasificación requiere confirmación explícita del '
              'agente aduanero (Ley 7557).',
              style: TextStyle(color: AduaNextTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openDrawer,
              icon: const Icon(Icons.search, size: 16),
              label: const Text('Abrir clasificador →'),
            ),
          ],
        ),
      ),
    );
  }
}
