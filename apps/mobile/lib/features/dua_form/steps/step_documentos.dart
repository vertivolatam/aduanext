/// Step 6: Documentos — required-document checklist.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/aduanext_theme.dart';
import '../data/required_documents.dart';
import '../dua_form_notifier.dart';
import '../widgets/document_row.dart';

class StepDocumentos extends ConsumerStatefulWidget {
  const StepDocumentos({super.key});

  @override
  ConsumerState<StepDocumentos> createState() => _StepDocumentosState();
}

class _StepDocumentosState extends ConsumerState<StepDocumentos> {
  /// Tracks whether we've seeded at least once, and for which
  /// transport mode. When the restore finishes asynchronously the
  /// `ref.listen` callback re-seeds with the now-correct mode.
  bool _hasSeeded = false;
  String? _seededForTransport;

  void _maybeSeed(String? transportMode, List<dynamic> existing) {
    if (existing.isNotEmpty) {
      _hasSeeded = true;
      _seededForTransport = transportMode;
      return;
    }
    if (_hasSeeded && _seededForTransport == transportMode) return;
    _hasSeeded = true;
    _seededForTransport = transportMode;
    // Defer the mutation until after the current frame — mutating
    // state during build is forbidden by Riverpod.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(duaFormProvider.notifier).seedDocumentsIfEmpty(
            defaultRequiredDocuments(transportModeCode: transportMode),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    // React to state changes from restore / transport-mode edits.
    ref.listen(duaFormProvider, (prev, next) {
      _maybeSeed(next.transportModeCode, next.documents);
    });
    final draft = ref.watch(duaFormProvider);
    _maybeSeed(draft.transportModeCode, draft.documents);
    final notifier = ref.read(duaFormProvider.notifier);

    final missingRequired =
        draft.documents.where((d) => d.required && !d.attached).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Documentos de respaldo',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
            'Adjunta los documentos segun el regimen y medio de transporte. '
            'Los marcados REQUERIDO deben estar presentes antes de transmitir.',
            style: TextStyle(color: AduaNextTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          if (missingRequired > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AduaNextTheme.stepperRojoBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AduaNextTheme.stepperRojo),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 16, color: AduaNextTheme.stepperRojo),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Faltan $missingRequired documento(s) requerido(s). '
                      'El submit se bloqueara hasta completarlos.',
                      style: const TextStyle(
                          color: AduaNextTheme.stepperRojo, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          for (var i = 0; i < draft.documents.length; i++)
            DocumentRow(
              key: ValueKey('doc-${draft.documents[i].code}-$i'),
              document: draft.documents[i],
              onChanged: (d) => notifier.updateDocument(i, d),
              onRemove: draft.documents[i].required
                  ? null
                  : () => notifier.removeDocument(i),
            ),
          if (draft.documents.isEmpty) ...[
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Cargando checklist...',
                style: TextStyle(color: AduaNextTheme.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
