/// Organism: rejected-DUA error panel.
///
/// Rendered as the footer inside [DuaListItem] when `status == rejected`.
/// Mirrors the mockup: a red-tinted block with the ATENA error code
/// (e.g. "E-VAL-0042"), the long Spanish description, and a
/// "Rectificar →" action.
library;

import 'package:flutter/material.dart';

import '../../api/dispatch_dto.dart';
import '../../theme/aduanext_theme.dart';

class DuaRejectedPanel extends StatelessWidget {
  final DispatchError error;

  /// Fires when the agent taps "Rectificar →". Wires through to
  /// VRTV-48 (rectification flow) once that PR lands — for now the
  /// dashboard surfaces a "coming soon" banner.
  final VoidCallback? onRectify;

  const DuaRejectedPanel({
    super.key,
    required this.error,
    this.onRectify,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AduaNextTheme.statusRechazadaBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AduaNextTheme.stepperRojo),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Error ATENA: ${error.code}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AduaNextTheme.statusRechazada,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: onRectify,
                style: TextButton.styleFrom(
                  backgroundColor: AduaNextTheme.stepperRojo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'Rectificar →',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            error.message,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFFCC8888),
            ),
          ),
        ],
      ),
    );
  }
}
