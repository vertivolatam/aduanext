/// Molecule: search input + mode chips for the RIMM drawer.
///
/// The mockup pairs a `<TextField>` with three mode chips
/// (FULL_TEXT / AI Sugerencia / Por HS Code). The agent types the
/// commercial description, picks a mode, and taps "Buscar" — this
/// widget owns none of that state; it emits callbacks for the parent
/// drawer to coordinate.
library;

import 'package:flutter/material.dart';

import '../../../features/classifier/classification_dto.dart';
import '../../theme/aduanext_theme.dart';

class ClassificationSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ClassificationSearchMode mode;
  final ValueChanged<ClassificationSearchMode> onModeChanged;
  final VoidCallback onSubmit;

  /// Shown when the backend is processing a search — disables the
  /// submit button and narrows the text field.
  final bool loading;

  const ClassificationSearchBar({
    super.key,
    required this.controller,
    required this.mode,
    required this.onModeChanged,
    required this.onSubmit,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DESCRIPCIÓN COMERCIAL',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: AduaNextTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => onSubmit(),
                enabled: !loading,
                decoration: const InputDecoration(
                  hintText: 'Ej. Reflector parabólico LED aluminio',
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: loading ? null : onSubmit,
              child: loading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Buscar'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: [
            for (final m in ClassificationSearchMode.values)
              _ModeChip(
                mode: m,
                selected: m == mode,
                onTap: () => onModeChanged(m),
              ),
          ],
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final ClassificationSearchMode mode;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: selected
                ? AduaNextTheme.surfacePanel
                : AduaNextTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AduaNextTheme.primary
                  : AduaNextTheme.borderSubtle,
            ),
          ),
          child: Text(
            mode.displayName,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
              color: selected
                  ? AduaNextTheme.primary
                  : AduaNextTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
