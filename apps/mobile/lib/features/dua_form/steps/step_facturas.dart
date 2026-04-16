/// Step 5: Facturas — multi-invoice list.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/aduanext_theme.dart';
import '../dua_form_notifier.dart';
import '../widgets/invoice_row.dart';

class StepFacturas extends ConsumerWidget {
  const StepFacturas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(duaFormProvider);
    final notifier = ref.read(duaFormProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Facturas',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    const Text(
                      'Lista una factura por envio comercial. El total debe '
                      'cuadrar con la suma FOB de los items (tolerancia 5%).',
                      style:
                          TextStyle(color: AduaNextTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => notifier.addInvoice(),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Agregar factura'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (draft.invoices.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AduaNextTheme.surfaceCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AduaNextTheme.borderSubtle),
              ),
              child: const Column(
                children: [
                  Icon(Icons.receipt_long,
                      size: 32, color: AduaNextTheme.textSecondary),
                  SizedBox(height: 8),
                  Text(
                    'Sin facturas. Agrega al menos una para continuar.',
                    style: TextStyle(color: AduaNextTheme.textSecondary),
                  ),
                ],
              ),
            )
          else
            for (var i = 0; i < draft.invoices.length; i++)
              InvoiceRow(
                key: ValueKey('invoice-$i'),
                index: i,
                invoice: draft.invoices[i],
                onChanged: (next) => notifier.updateInvoice(i, next),
                onRemove: () => notifier.removeInvoice(i),
              ),
          if (draft.invoices.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AduaNextTheme.surfacePanel,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AduaNextTheme.borderSubtle),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL FACTURAS',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                      color: AduaNextTheme.textSecondary,
                    ),
                  ),
                  Text(
                    draft.totalInvoiceAmount.toStringAsFixed(2),
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
