/// Molecule: a single invoice row for Step 5.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../shared/theme/aduanext_theme.dart';
import '../dua_form_state.dart';
import 'currency_picker.dart';

class InvoiceRow extends StatefulWidget {
  final int index;
  final DuaDraftInvoice invoice;
  final ValueChanged<DuaDraftInvoice> onChanged;
  final VoidCallback onRemove;

  const InvoiceRow({
    super.key,
    required this.index,
    required this.invoice,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<InvoiceRow> createState() => _InvoiceRowState();
}

class _InvoiceRowState extends State<InvoiceRow> {
  late final TextEditingController _number;
  late final TextEditingController _supplier;
  late final TextEditingController _total;

  @override
  void initState() {
    super.initState();
    _number = TextEditingController(text: widget.invoice.number);
    _supplier = TextEditingController(text: widget.invoice.supplier);
    _total = TextEditingController(
      text: widget.invoice.totalAmount == null ||
              widget.invoice.totalAmount == 0
          ? ''
          : widget.invoice.totalAmount!.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _number.dispose();
    _supplier.dispose();
    _total.dispose();
    super.dispose();
  }

  void _push(DuaDraftInvoice next) => widget.onChanged(next);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.invoice.issueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      _push(widget.invoice.copyWith(issueDate: picked));
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  'Factura',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: AduaNextTheme.textSecondary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Eliminar factura',
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: widget.onRemove,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _number,
                  decoration: const InputDecoration(
                    labelText: 'Numero de factura',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => _push(widget.invoice.copyWith(number: v)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha emision',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      widget.invoice.issueDate == null
                          ? 'Selecciona fecha'
                          : DateFormat.yMMMd().format(widget.invoice.issueDate!),
                      style: TextStyle(
                        color: widget.invoice.issueDate == null
                            ? AduaNextTheme.textSecondary
                            : AduaNextTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _supplier,
            decoration: const InputDecoration(
              labelText: 'Proveedor / emisor',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => _push(widget.invoice.copyWith(supplier: v)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _total,
                  decoration: const InputDecoration(
                    labelText: 'Monto total',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  onChanged: (v) {
                    _push(widget.invoice
                        .copyWith(totalAmount: double.tryParse(v) ?? 0));
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CurrencyPicker(
                  label: 'Moneda',
                  selectedCode: widget.invoice.currencyCode,
                  onChanged: (code) =>
                      _push(widget.invoice.copyWith(currencyCode: code)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
