import 'package:aduanext_ui/aduanext_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: TariffRateCell, path: '[atoms]')
Widget buildTariffRateCellUseCase(BuildContext context) {
  return TariffRateCell(
    label: context.knobs.string(
      label: 'Label',
      initialValue: 'DAI',
    ),
    percent: context.knobs.double.slider(
      label: 'Percent',
      initialValue: 15,
      min: 0,
      max: 100,
    ),
    tintAbove: context.knobs.doubleOrNull.slider(
      label: 'Tint above',
      initialValue: 10,
      min: 0,
      max: 100,
    ),
  );
}
