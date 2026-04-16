/// Organism: the RIMM classifier drawer.
///
/// 420px wide, slides in from the right over a dimmed background
/// (the host scaffold owns the `endDrawer` slot). Matches mockup
/// `07-rimm-classifier.html`:
///
///   1. Drawer header (item number + close button)
///   2. Search bar + mode chips
///   3. Results list (top-5 suggestions with "RECOMENDADO")
///   4. Footer: Ley 7557 warning + Cancelar / Seleccionar confirm
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/api/api_exception.dart';
import '../../shared/theme/aduanext_theme.dart';
import '../../shared/ui/molecules/classification_search_bar.dart';
import '../../shared/ui/molecules/classification_suggestion_card.dart';
import 'classification_dto.dart';
import 'classifier_providers.dart';

/// Result emitted when the agent confirms a classification. The
/// parent widget (DUA form item, classifier page) persists it via
/// the backend's RecordClassificationCommand.
class ClassifierConfirmation {
  final ClassificationSuggestion suggestion;
  final String searchDescription;
  final ClassificationSearchMode mode;

  const ClassifierConfirmation({
    required this.suggestion,
    required this.searchDescription,
    required this.mode,
  });
}

class ClassifierDrawer extends ConsumerStatefulWidget {
  /// Optional subtitle shown above the search input — used by the
  /// DUA form to echo the item being classified ("Item 3: Reflector
  /// parabólico de aluminio").
  final String? contextLabel;

  /// Seed text for the search input. Lets the DUA form pre-fill the
  /// commercial description from the item row.
  final String? initialDescription;

  /// Fires when the agent taps the confirm button with a selection.
  final ValueChanged<ClassifierConfirmation> onConfirm;

  const ClassifierDrawer({
    super.key,
    required this.onConfirm,
    this.contextLabel,
    this.initialDescription,
  });

  @override
  ConsumerState<ClassifierDrawer> createState() => _ClassifierDrawerState();
}

class _ClassifierDrawerState extends ConsumerState<ClassifierDrawer> {
  late final TextEditingController _ctrl;
  ClassificationSearchMode _mode = ClassificationSearchMode.aiSuggestion;
  ClassificationSuggestion? _selected;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialDescription ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _selected = null);
    ref.read(classifierQueryProvider.notifier).state = ClassifierQuery(
      description: text,
      mode: _mode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final suggestionsAsync = ref.watch(classificationSuggestionsProvider);

    return Drawer(
      width: 420,
      backgroundColor: AduaNextTheme.surfacePanel,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          children: [
            _Header(contextLabel: widget.contextLabel),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AduaNextTheme.surfaceCard),
                ),
              ),
              child: ClassificationSearchBar(
                controller: _ctrl,
                mode: _mode,
                onModeChanged: (m) => setState(() => _mode = m),
                onSubmit: _onSubmit,
                loading: suggestionsAsync.isLoading,
              ),
            ),
            Expanded(
              child: _ResultsArea(
                async: suggestionsAsync,
                selected: _selected,
                onSelect: (s) => setState(() => _selected = s),
              ),
            ),
            _Footer(
              confirmEnabled: _selected != null,
              onCancel: () => Navigator.of(context).maybePop(),
              onConfirm: () {
                final sel = _selected;
                if (sel == null) return;
                widget.onConfirm(
                  ClassifierConfirmation(
                    suggestion: sel,
                    searchDescription: _ctrl.text.trim(),
                    mode: _mode,
                  ),
                );
                Navigator.of(context).maybePop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String? contextLabel;
  const _Header({this.contextLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AduaNextTheme.surfaceCard),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Clasificador RIMM',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (contextLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    contextLabel!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AduaNextTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cerrar',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}

class _ResultsArea extends StatelessWidget {
  final AsyncValue<ClassificationSuggestResponse?> async;
  final ClassificationSuggestion? selected;
  final ValueChanged<ClassificationSuggestion> onSelect;

  const _ResultsArea({
    required this.async,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorState(error: err),
      data: (response) {
        if (response == null) return const _Empty();
        if (response.suggestions.isEmpty) {
          return const _NoResults();
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${response.suggestions.length} resultados — ordenados por '
                'confianza AI',
                style: const TextStyle(
                  fontSize: 10,
                  color: AduaNextTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < response.suggestions.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ClassificationSuggestionCard(
                    suggestion: response.suggestions[i],
                    recommended: i == 0,
                    selected:
                        selected?.hsCode == response.suggestions[i].hsCode,
                    onTap: () => onSelect(response.suggestions[i]),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Ingresa la descripción comercial y pulsa Buscar para obtener '
          'sugerencias de HS code.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AduaNextTheme.textSecondary),
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Sin coincidencias. Intenta con una descripción más específica o '
          'cambia el modo de búsqueda.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AduaNextTheme.textSecondary),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Object error;
  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    final notImpl = error is NotImplementedApiException;
    final message = error is ApiException
        ? (error as ApiException).message
        : 'Error inesperado al buscar sugerencias.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              notImpl ? Icons.construction : Icons.error_outline,
              size: 40,
              color: AduaNextTheme.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AduaNextTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final bool confirmEnabled;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _Footer({
    required this.confirmEnabled,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AduaNextTheme.surfaceRail,
        border: Border(
          top: BorderSide(color: AduaNextTheme.borderSubtle),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AduaNextTheme.statusValidandoBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AduaNextTheme.stepperAmarillo),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: AduaNextTheme.statusValidando,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'La clasificación requiere confirmación del agente '
                    'aduanero (Ley 7557). Una vez confirmada, no puede '
                    'modificarse — solo crear nueva clasificación.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 10,
                          color: AduaNextTheme.statusValidando,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: confirmEnabled ? onConfirm : null,
                  child: const Text('Confirmar selección'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
