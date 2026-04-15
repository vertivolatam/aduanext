/// Modal dialog that presents the enumerated [TokenSlot]s and
/// returns the one the user picked.
///
/// Each row shows the token label, serial, and (when available) the
/// Common Name from the token's signing certificate. Tokens that do
/// not carry a certificate are rendered disabled — they cannot sign
/// a DUA and picking them would only lead to a downstream error.
library;

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:flutter/material.dart';

class TokenPickerDialog extends StatelessWidget {
  final List<TokenSlot> slots;

  const TokenPickerDialog({super.key, required this.slots});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Selecciona tu token'),
      content: SizedBox(
        width: 480,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: slots.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final s = slots[i];
            final subtitle = <String>[
              if (s.certCommonName != null) s.certCommonName!,
              'Serie: ${s.tokenSerial}',
              if (!s.hasCert) 'Sin certificado — no se puede firmar',
            ].join(' - ');
            return ListTile(
              key: Key('token-slot-${s.slotId}'),
              enabled: s.hasCert,
              leading: Icon(
                s.hasCert ? Icons.usb : Icons.usb_off_outlined,
                color: s.hasCert ? Colors.green : null,
              ),
              title: Text(s.tokenLabel.isEmpty ? 'Token' : s.tokenLabel),
              subtitle: Text(subtitle),
              trailing: Text('Slot ${s.slotId}'),
              onTap: s.hasCert ? () => Navigator.of(context).pop(s) : null,
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
