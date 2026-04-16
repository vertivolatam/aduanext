/// Molecule: live CIF calculator.
///
/// Displays FOB (from items sum, read-only), freight (editable),
/// insurance (editable) and the computed CIF below them. Emits
/// changes via callbacks — the parent step writes to the notifier.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/theme/aduanext_theme.dart';

class CifCalculator extends StatefulWidget {
  final double fobAmount;
  final double? freightAmount;
  final double? insuranceAmount;
  final ValueChanged<double> onFreightChanged;
  final ValueChanged<double> onInsuranceChanged;
  final String currencyLabel;

  const CifCalculator({
    super.key,
    required this.fobAmount,
    required this.freightAmount,
    required this.insuranceAmount,
    required this.onFreightChanged,
    required this.onInsuranceChanged,
    this.currencyLabel = '',
  });

  @override
  State<CifCalculator> createState() => _CifCalculatorState();
}

class _CifCalculatorState extends State<CifCalculator> {
  late final TextEditingController _freight;
  late final TextEditingController _insurance;

  static String _fmt(double? v) {
    if (v == null) return '';
    if (v == 0) return '';
    return v.toStringAsFixed(2);
  }

  @override
  void initState() {
    super.initState();
    _freight = TextEditingController(text: _fmt(widget.freightAmount));
    _insurance = TextEditingController(text: _fmt(widget.insuranceAmount));
  }

  @override
  void didUpdateWidget(covariant CifCalculator oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync controller text if the draft was restored externally.
    if (oldWidget.freightAmount != widget.freightAmount &&
        double.tryParse(_freight.text) != widget.freightAmount) {
      _freight.text = _fmt(widget.freightAmount);
    }
    if (oldWidget.insuranceAmount != widget.insuranceAmount &&
        double.tryParse(_insurance.text) != widget.insuranceAmount) {
      _insurance.text = _fmt(widget.insuranceAmount);
    }
  }

  @override
  void dispose() {
    _freight.dispose();
    _insurance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cif = widget.fobAmount +
        (widget.freightAmount ?? 0) +
        (widget.insuranceAmount ?? 0);
    final currencySuffix =
        widget.currencyLabel.isEmpty ? '' : ' ${widget.currencyLabel}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AduaNextTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AduaNextTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'CALCULO CIF',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              color: AduaNextTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _Row(
            label: 'FOB (suma items)',
            valueText: widget.fobAmount.toStringAsFixed(2) + currencySuffix,
            readOnly: true,
          ),
          const SizedBox(height: 8),
          _EditableRow(
            label: 'Flete',
            controller: _freight,
            suffix: currencySuffix,
            onChanged: (v) =>
                widget.onFreightChanged(double.tryParse(v) ?? 0),
          ),
          const SizedBox(height: 8),
          _EditableRow(
            label: 'Seguro',
            controller: _insurance,
            suffix: currencySuffix,
            onChanged: (v) =>
                widget.onInsuranceChanged(double.tryParse(v) ?? 0),
          ),
          const SizedBox(height: 12),
          const Divider(color: AduaNextTheme.borderSubtle),
          const SizedBox(height: 8),
          _Row(
            label: 'CIF',
            valueText: cif.toStringAsFixed(2) + currencySuffix,
            readOnly: true,
            emphasize: true,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String valueText;
  final bool readOnly;
  final bool emphasize;
  const _Row({
    required this.label,
    required this.valueText,
    this.readOnly = false,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: emphasize ? 14 : 12,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              color: emphasize
                  ? AduaNextTheme.textPrimary
                  : AduaNextTheme.textSecondary,
            ),
          ),
        ),
        Text(
          valueText.isEmpty ? '0.00' : valueText,
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: emphasize ? 18 : 13,
            fontWeight: FontWeight.w700,
            color: emphasize
                ? AduaNextTheme.primaryLight
                : AduaNextTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _EditableRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String suffix;
  final ValueChanged<String> onChanged;

  const _EditableRow({
    required this.label,
    required this.controller,
    required this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AduaNextTheme.textSecondary,
            ),
          ),
        ),
        SizedBox(
          width: 160,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              isDense: true,
              suffixText: suffix.trim().isEmpty ? null : suffix.trim(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
            style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13),
            textAlign: TextAlign.right,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
