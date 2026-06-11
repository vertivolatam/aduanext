import 'package:aduanext_domain/aduanext_domain.dart' hide Container;
import 'package:aduanext_mobile/shared/ui/atoms/declaration_status_semaphore.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: 'Default',
  type: DeclarationStatusSemaphore,
  path: '[atoms]',
)
Widget buildDeclarationStatusSemaphoreUseCase(BuildContext context) {
  return DeclarationStatusSemaphore(
    status: context.knobs.object.dropdown(
      label: 'Status',
      options: DeclarationStatus.values,
      labelBuilder: (status) => status.name,
    ),
    compact: context.knobs.boolean(
      label: 'Compact',
      initialValue: false,
    ),
  );
}
