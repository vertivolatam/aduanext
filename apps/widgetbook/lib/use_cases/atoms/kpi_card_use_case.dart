import 'package:aduanext_ui/aduanext_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: KpiCard, path: '[atoms]')
Widget buildKpiCardUseCase(BuildContext context) {
  final loading = context.knobs.boolean(
    label: 'Loading (skeleton)',
    initialValue: false,
  );
  return KpiCard(
    label: context.knobs.string(
      label: 'Label',
      initialValue: 'LEVANTE',
    ),
    value: loading
        ? null
        : context.knobs.int.slider(
            label: 'Value',
            initialValue: 12,
            min: 0,
            max: 99,
          ),
    tone: context.knobs.object.dropdown(
      label: 'Tone',
      options: StatusTone.values,
      labelBuilder: (tone) => tone.name,
    ),
  );
}
