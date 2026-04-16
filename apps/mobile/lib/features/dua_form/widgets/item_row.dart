/// Molecule: a single DUA line item row.
///
/// Edits one [DuaDraftLineItem] at a time:
///   * Commercial description (textarea)
///   * HS code + "Clasificar con RIMM" button → opens the
///     [ClassifierDrawer] from VRTV-44
///   * Quantity, gross mass, FOB amount
///
/// Emits change callbacks so the parent step widget can call
/// `notifier.updateItem(index, item)`.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/theme/aduanext_theme.dart';
import '../../../shared/ui/atoms/hs_code_chip.dart';
import '../dua_form_state.dart';

class ItemRow extends StatefulWidget {
  final int index;
  final DuaDraftLineItem item;
  final ValueChanged<DuaDraftLineItem> onChanged;
  final VoidCallback onRemove;

  /// Opens the RIMM classifier drawer with the current commercial
  /// description pre-filled. Parent wires to `Scaffold.of(context)
  /// .openEndDrawer()` + a completer that returns the confirmed
  /// suggestion. When the drawer is unavailable (widget tests), the
  /// button is hidden.
  final Future<String?> Function(String description)? onRequestClassify;

  const ItemRow({
    super.key,
    required this.index,
    required this.item,
    required this.onChanged,
    required this.onRemove,
    this.onRequestClassify,
  });

  @override
  State<ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<ItemRow> {
  late final TextEditingController _description;
  late final TextEditingController _quantity;
  late final TextEditingController _grossMass;
  late final TextEditingController _fob;

  @override
  void initState() {
    super.initState();
    _description =
        TextEditingController(text: widget.item.commercialDescription);
    _quantity = TextEditingController(
        text: widget.item.quantity == null
            ? ''
            : _stripTrailingZeros(widget.item.quantity!));
    _grossMass = TextEditingController(
        text: widget.item.grossMassKg == null
            ? ''
            : _stripTrailingZeros(widget.item.grossMassKg!));
    _fob = TextEditingController(
        text: widget.item.fobAmount == null
            ? ''
            : _stripTrailingZeros(widget.item.fobAmount!));
  }

  static String _stripTrailingZeros(double v) {
    // Keep up to 4 decimals but drop trailing zeros to stay readable.
    var s = v.toStringAsFixed(4);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return s;
  }

  @override
  void dispose() {
    _description.dispose();
    _quantity.dispose();
    _grossMass.dispose();
    _fob.dispose();
    super.dispose();
  }

  void _push(DuaDraftLineItem next) => widget.onChanged(next);

  Future<void> _openClassifier() async {
    final fn = widget.onRequestClassify;
    if (fn == null) return;
    final hs = await fn(_description.text.trim());
    if (hs != null && mounted) {
      _push(widget.item.copyWith(hsCode: hs));
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = (widget.item.quantity ?? 0) * (widget.item.fobAmount ?? 0);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AduaNextTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AduaNextTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AduaNextTheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Item',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: AduaNextTheme.textSecondary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Eliminar item',
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: widget.onRemove,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _description,
            decoration: const InputDecoration(
              labelText: 'Descripcion comercial',
              hintText: 'Ej. Reflector parabolico de aluminio 50W',
              border: OutlineInputBorder(),
            ),
            minLines: 2,
            maxLines: 3,
            onChanged: (v) =>
                _push(widget.item.copyWith(commercialDescription: v)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: widget.item.hsCode == null
                    ? const Text(
                        'Sin clasificar',
                        style: TextStyle(
                          fontSize: 12,
                          color: AduaNextTheme.textSecondary,
                        ),
                      )
                    : HsCodeChip(
                        code: widget.item.hsCode!,
                        size: HsCodeChipSize.small,
                      ),
              ),
              if (widget.onRequestClassify != null)
                OutlinedButton.icon(
                  onPressed: _openClassifier,
                  icon: const Icon(Icons.auto_awesome, size: 14),
                  label: Text(widget.item.hsCode == null
                      ? 'Clasificar con RIMM'
                      : 'Reclasificar'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quantity,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  onChanged: (v) {
                    _push(widget.item
                        .copyWith(quantity: double.tryParse(v) ?? 0));
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _grossMass,
                  decoration: const InputDecoration(
                    labelText: 'Masa bruta (kg)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  onChanged: (v) {
                    _push(widget.item
                        .copyWith(grossMassKg: double.tryParse(v) ?? 0));
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _fob,
                  decoration: const InputDecoration(
                    labelText: 'FOB (unitario)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  onChanged: (v) {
                    _push(widget.item
                        .copyWith(fobAmount: double.tryParse(v) ?? 0));
                  },
                ),
              ),
            ],
          ),
          if (subtotal > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Subtotal: ',
                  style: TextStyle(
                    fontSize: 11,
                    color: AduaNextTheme.textSecondary,
                  ),
                ),
                Text(
                  subtotal.toStringAsFixed(2),
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
