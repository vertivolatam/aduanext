import 'package:aduanext_domain/aduanext_domain.dart' hide Container;
import 'package:aduanext_mobile/shared/ui/molecules/status_filter_chips.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: StatusFilterChips, path: '[molecules]')
Widget buildStatusFilterChipsUseCase(BuildContext context) {
  return _InteractiveStatusFilterChips(
    initialSelected: {
      context.knobs.object.dropdown(
        label: 'Selección inicial',
        options: StatusFilterChips.defaultStatuses,
        labelBuilder: (status) => status.name,
      ),
    },
  );
}

/// Wrapper con estado para que los chips respondan al toque dentro
/// del story (el widget real delega la selección al padre).
class _InteractiveStatusFilterChips extends StatefulWidget {
  final Set<DeclarationStatus> initialSelected;

  const _InteractiveStatusFilterChips({required this.initialSelected});

  @override
  State<_InteractiveStatusFilterChips> createState() =>
      _InteractiveStatusFilterChipsState();
}

class _InteractiveStatusFilterChipsState
    extends State<_InteractiveStatusFilterChips> {
  late Set<DeclarationStatus> _selected = widget.initialSelected;

  @override
  Widget build(BuildContext context) {
    return StatusFilterChips(
      selected: _selected,
      onChanged: (next) => setState(() => _selected = next),
    );
  }
}
