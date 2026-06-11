import 'package:aduanext_ui/aduanext_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: KpiRow, path: '[molecules]')
Widget buildKpiRowUseCase(BuildContext context) {
  return KpiRow(
    summary: KpiSummary(
      activas: context.knobs.int.slider(
        label: 'Activas',
        initialValue: 24,
        min: 0,
        max: 99,
      ),
      levante: context.knobs.int.slider(
        label: 'Levante',
        initialValue: 12,
        min: 0,
        max: 99,
      ),
      enProceso: context.knobs.int.slider(
        label: 'En proceso',
        initialValue: 8,
        min: 0,
        max: 99,
      ),
      requiereAccion: context.knobs.int.slider(
        label: 'Requiere acción',
        initialValue: 4,
        min: 0,
        max: 99,
      ),
    ),
  );
}
