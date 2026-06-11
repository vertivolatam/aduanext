import 'package:aduanext_ui/aduanext_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: HsCodeChip, path: '[atoms]')
Widget buildHsCodeChipUseCase(BuildContext context) {
  return HsCodeChip(
    code: context.knobs.string(
      label: 'HS Code',
      initialValue: '8471.30.00.00',
    ),
    accent: context.knobs.boolean(
      label: 'Accent',
      initialValue: false,
    ),
    size: context.knobs.object.dropdown(
      label: 'Size',
      options: HsCodeChipSize.values,
      labelBuilder: (size) => size.name,
    ),
  );
}
