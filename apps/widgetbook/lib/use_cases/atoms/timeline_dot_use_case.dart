import 'package:aduanext_mobile/shared/ui/atoms/declaration_status_semaphore.dart';
import 'package:aduanext_mobile/shared/ui/atoms/timeline_dot.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: TimelineDot, path: '[atoms]')
Widget buildTimelineDotUseCase(BuildContext context) {
  return TimelineDot(
    state: context.knobs.object.dropdown(
      label: 'State',
      options: TimelineDotState.values,
      labelBuilder: (state) => state.name,
    ),
    tone: context.knobs.object.dropdown(
      label: 'Tone',
      options: StatusTone.values,
      labelBuilder: (tone) => tone.name,
    ),
    prominent: context.knobs.boolean(
      label: 'Prominent',
      initialValue: false,
    ),
  );
}
