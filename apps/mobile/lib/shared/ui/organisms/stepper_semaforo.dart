/// Organism: horizontal stepper semáforo for the DUA form.
///
/// Renders one numbered bubble per [DuaFormStep] plus a connector
/// line between bubbles. The parent supplies a `toneBuilder` so the
/// stepper stays pure — tone logic lives on the form notifier.
///
/// Tone palette (matches `06-stepper-semaforo.html`):
///   * verde    — fondo oscuro, borde + texto #4CAF50
///   * amarillo — fondo oscuro, borde + texto #FF9800
///   * azul     — fondo primary, borde claro, texto blanco
///   * rojo     — fondo oscuro rojizo, borde + texto #EF5350, opacity 50%
library;

import 'package:flutter/material.dart';

import '../../../features/dua_form/steps.dart';
import '../../theme/aduanext_theme.dart';

typedef StepperToneBuilder = StepperTone Function(DuaFormStep step);

class StepperSemaforo extends StatelessWidget {
  final DuaFormStep activeStep;
  final StepperToneBuilder toneBuilder;
  final ValueChanged<DuaFormStep> onStepTap;

  /// When false, bubbles of [StepperTone.rojo] ignore taps. Always
  /// true — exposed for tests / future design experiments.
  final bool enforceLock;

  const StepperSemaforo({
    super.key,
    required this.activeStep,
    required this.toneBuilder,
    required this.onStepTap,
    this.enforceLock = true,
  });

  @override
  Widget build(BuildContext context) {
    final steps = DuaFormStep.values;
    final children = <Widget>[];
    for (var i = 0; i < steps.length; i++) {
      final step = steps[i];
      final tone = toneBuilder(step);
      children.add(_StepBubble(
        step: step,
        tone: tone,
        onTap: enforceLock && tone == StepperTone.rojo
            ? null
            : () => onStepTap(step),
      ));
      if (i < steps.length - 1) {
        final nextTone = toneBuilder(steps[i + 1]);
        children.add(Expanded(
          child: _Connector(
            leftTone: tone,
            rightTone: nextTone,
          ),
        ));
      }
    }

    // Horizontally scroll if the viewport can't fit all 7 bubbles +
    // connectors. The connector flex-grows to fill slack; on wide
    // viewports the Row stretches to the full width, on narrow
    // viewports the user can scroll. IntrinsicWidth + min-sized
    // SingleChildScrollView keeps the measured size honest.
    return Container(
      decoration: const BoxDecoration(
        color: AduaNextTheme.surfacePanel,
        border: Border(
          top: BorderSide(color: AduaNextTheme.borderSubtle),
          bottom: BorderSide(color: AduaNextTheme.borderSubtle),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Minimum needed: ~90px per bubble + ~20px min connector.
          const minWidth = 7 * 110.0;
          if (constraints.maxWidth >= minWidth) {
            return Row(children: children);
          }
          // Narrow viewport — drop the Expanded (it doesn't work in a
          // scrollable) and let the row assume its intrinsic size.
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: IntrinsicWidth(
              child: Row(
                children: _unexpandConnectors(children),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Replace `Expanded(child: Connector)` with a fixed-width Connector
  /// wrapper so the row computes a bounded intrinsic width.
  List<Widget> _unexpandConnectors(List<Widget> children) {
    return children.map((c) {
      if (c is Expanded) {
        return const SizedBox(width: 40, child: _FixedConnector());
      }
      return c;
    }).toList(growable: false);
  }
}

class _FixedConnector extends StatelessWidget {
  const _FixedConnector();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AduaNextTheme.borderSubtle,
    );
  }
}

class _StepBubble extends StatelessWidget {
  final DuaFormStep step;
  final StepperTone tone;
  final VoidCallback? onTap;

  const _StepBubble({
    required this.step,
    required this.tone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, border, text, opacity) = _colors(tone);
    return Opacity(
      opacity: opacity,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: Border.all(color: border, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                '${step.ordinal}',
                style: TextStyle(
                  fontSize: 11,
                  color: text,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              step.displayName,
              style: TextStyle(
                fontSize: 12,
                color: text,
                fontWeight: tone == StepperTone.azul
                    ? FontWeight.w700
                    : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// (background, border, textColor, opacity) for the tone.
  (Color, Color, Color, double) _colors(StepperTone tone) {
    switch (tone) {
      case StepperTone.verde:
        return (
          AduaNextTheme.stepperVerdeBg,
          AduaNextTheme.stepperVerde,
          AduaNextTheme.stepperVerde,
          1.0,
        );
      case StepperTone.amarillo:
        return (
          AduaNextTheme.stepperAmarilloBg,
          AduaNextTheme.stepperAmarillo,
          AduaNextTheme.stepperAmarillo,
          1.0,
        );
      case StepperTone.azul:
        return (
          AduaNextTheme.stepperAzul,
          AduaNextTheme.primaryLight,
          Colors.white,
          1.0,
        );
      case StepperTone.rojo:
        return (
          AduaNextTheme.stepperRojoBg,
          AduaNextTheme.stepperRojo,
          AduaNextTheme.stepperRojo,
          0.5,
        );
    }
  }
}

class _Connector extends StatelessWidget {
  final StepperTone leftTone;
  final StepperTone rightTone;

  const _Connector({required this.leftTone, required this.rightTone});

  @override
  Widget build(BuildContext context) {
    // Left side of the connector inherits the left bubble's tone so
    // the eye traces continuity: green arrow → yellow arrow → blue
    // current. Right side gets the neutral border color when the
    // right bubble is still locked.
    final leftColor = _edgeColor(leftTone);
    final rightColor = _edgeColor(rightTone);

    // Simple gradient is overkill for 2 states; render two halves.
    return Row(
      children: [
        Expanded(child: Container(height: 2, color: leftColor)),
        Expanded(child: Container(height: 2, color: rightColor)),
      ],
    );
  }

  Color _edgeColor(StepperTone tone) {
    switch (tone) {
      case StepperTone.verde:
        return AduaNextTheme.stepperVerdeBg;
      case StepperTone.amarillo:
        return AduaNextTheme.stepperAmarilloBg;
      case StepperTone.azul:
        return AduaNextTheme.stepperAzul;
      case StepperTone.rojo:
        return AduaNextTheme.borderSubtle;
    }
  }
}
