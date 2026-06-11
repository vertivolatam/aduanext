import 'package:aduanext_ui/aduanext_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: RiskScoreBadge, path: '[atoms]')
Widget buildRiskScoreBadgeUseCase(BuildContext context) {
  final unknown = context.knobs.boolean(
    label: 'Score desconocido',
    initialValue: false,
  );
  return RiskScoreBadge(
    score: unknown
        ? null
        : context.knobs.int.slider(
            label: 'Score',
            initialValue: 35,
            min: 0,
            max: 100,
          ),
    compact: context.knobs.boolean(
      label: 'Compact',
      initialValue: false,
    ),
  );
}
