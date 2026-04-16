/// Molecule: a single document checklist row for Step 6.
///
/// Shows the doc name + required/optional badge + attach/replace
/// button. The actual file storage lands with VRTV-48; until then
/// the "attach" button stubs by recording a filename via a text
/// prompt.
library;

import 'package:flutter/material.dart';

import '../../../shared/theme/aduanext_theme.dart';
import '../dua_form_state.dart';

class DocumentRow extends StatelessWidget {
  final DuaDraftDocument document;
  final ValueChanged<DuaDraftDocument> onChanged;
  final VoidCallback? onRemove;

  const DocumentRow({
    super.key,
    required this.document,
    required this.onChanged,
    this.onRemove,
  });

  Future<void> _attach(BuildContext context) async {
    // Stub attach: prompt for a filename so the agent can at least
    // mark the doc as "provided" during MVP. Real upload ships with
    // VRTV-48.
    final controller = TextEditingController(text: document.fileName ?? '');
    final fileName = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(document.displayName),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nombre del archivo',
              hintText: 'factura-123.pdf',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Adjuntar'),
            ),
          ],
        );
      },
    );
    if (fileName != null && fileName.isNotEmpty) {
      onChanged(document.copyWith(fileName: fileName));
    }
  }

  @override
  Widget build(BuildContext context) {
    final attached = document.attached;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AduaNextTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: attached
              ? AduaNextTheme.stepperVerde
              : (document.required
                  ? AduaNextTheme.stepperRojo
                  : AduaNextTheme.borderSubtle),
        ),
      ),
      child: Row(
        children: [
          Icon(
            attached ? Icons.check_circle : Icons.description_outlined,
            size: 18,
            color: attached
                ? AduaNextTheme.stepperVerde
                : AduaNextTheme.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      document.displayName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: document.required
                            ? AduaNextTheme.stepperRojoBg
                            : AduaNextTheme.surfacePanel,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        document.required ? 'REQUERIDO' : 'OPCIONAL',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700,
                          color: document.required
                              ? AduaNextTheme.stepperRojo
                              : AduaNextTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  attached
                      ? document.fileName!
                      : 'Sin adjuntar',
                  style: TextStyle(
                    fontSize: 11,
                    color: attached
                        ? AduaNextTheme.textSecondary
                        : AduaNextTheme.textSecondary,
                    fontFamily: attached ? 'JetBrainsMono' : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => _attach(context),
            icon: Icon(
              attached ? Icons.autorenew : Icons.attach_file,
              size: 14,
            ),
            label: Text(attached ? 'Cambiar' : 'Adjuntar'),
          ),
          if (onRemove != null)
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.close, size: 16),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}
