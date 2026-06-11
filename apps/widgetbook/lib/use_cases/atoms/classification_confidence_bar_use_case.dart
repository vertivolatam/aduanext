import 'package:aduanext_ui/aduanext_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: 'Default',
  type: ClassificationConfidenceBar,
  path: '[atoms]',
)
Widget buildClassificationConfidenceBarUseCase(BuildContext context) {
  return ClassificationConfidenceBar(
    confidence: context.knobs.int.slider(
      label: 'Confidence',
      initialValue: 87,
      min: 0,
      max: 100,
    ),
    width: context.knobs.double.slider(
      label: 'Width',
      initialValue: 160,
      min: 80,
      max: 320,
    ),
  );
}
