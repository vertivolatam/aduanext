import 'package:aduanext_mobile/features/classifier/classification_dto.dart';
import 'package:aduanext_mobile/shared/ui/molecules/classification_suggestion_card.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: 'Default',
  type: ClassificationSuggestionCard,
  path: '[molecules]',
)
Widget buildClassificationSuggestionCardUseCase(BuildContext context) {
  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 420),
    child: ClassificationSuggestionCard(
      suggestion: ClassificationSuggestion(
        hsCode: context.knobs.string(
          label: 'HS Code',
          initialValue: '8471.30.00.00',
        ),
        description: context.knobs.string(
          label: 'Descripción',
          initialValue:
              'Máquinas automáticas para tratamiento de datos, portátiles, '
              'de peso inferior o igual a 10 kg',
        ),
        confidence: context.knobs.int.slider(
          label: 'Confidence',
          initialValue: 92,
          min: 0,
          max: 100,
        ),
        rates: const TariffRates(dai: 0, iva: 13, isc: 0),
      ),
      recommended: context.knobs.boolean(
        label: 'Recomendado',
        initialValue: true,
      ),
      selected: context.knobs.boolean(
        label: 'Seleccionado',
        initialValue: false,
      ),
      onTap: () {},
    ),
  );
}
