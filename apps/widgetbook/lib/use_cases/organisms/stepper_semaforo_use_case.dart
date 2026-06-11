import 'package:aduanext_mobile/features/dua_form/steps.dart';
import 'package:aduanext_mobile/shared/ui/organisms/stepper_semaforo.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: StepperSemaforo, path: '[organisms]')
Widget buildStepperSemaforoUseCase(BuildContext context) {
  final activeStep = context.knobs.object.dropdown(
    label: 'Paso activo',
    options: DuaFormStep.values,
    labelBuilder: (step) => step.displayName,
    initialOption: DuaFormStep.items,
  );
  final errorStep = context.knobs.objectOrNull.dropdown(
    label: 'Paso con error',
    options: DuaFormStep.values,
    labelBuilder: (step) => step?.displayName ?? 'ninguno',
    initialOption: null,
  );
  return StepperSemaforo(
    activeStep: activeStep,
    toneBuilder: (step) {
      if (step == errorStep) return StepperTone.rojo;
      if (step == activeStep) return StepperTone.azul;
      if (step.index < activeStep.index) return StepperTone.verde;
      return StepperTone.amarillo;
    },
    onStepTap: (_) {},
  );
}
