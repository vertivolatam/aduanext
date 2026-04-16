/// Molecule: multi-select filter chips for DeclarationStatus.
///
/// Renders one chip per status in a scrollable horizontal list. The
/// parent (VRTV-85 dashboard page) holds the selected set in Riverpod
/// and feeds it back so the chips reflect the current filter.
///
/// Chips use the `DeclarationStatus.displayName` for labels and color
/// the selection tint via the status tone (verde/amber/rojo/gris).
library;

// Hide `Container` — it's an ATENA manifest entity in the domain
// package and collides with Flutter's widget.
import 'package:aduanext_domain/aduanext_domain.dart' hide Container;
import 'package:flutter/material.dart';

import '../../theme/aduanext_theme.dart';
import '../atoms/declaration_status_semaphore.dart';

class StatusFilterChips extends StatelessWidget {
  final Set<DeclarationStatus> selected;
  final ValueChanged<Set<DeclarationStatus>> onChanged;

  /// Statuses to offer as filters. Defaults to the common 8 (draft,
  /// registered, validating, payment_pending, levante, rejected,
  /// annulled, confirmed) — the dashboard page can override to expose
  /// every status if a power-user view is ever needed.
  final List<DeclarationStatus> available;

  static const List<DeclarationStatus> defaultStatuses = [
    DeclarationStatus.draft,
    DeclarationStatus.registered,
    DeclarationStatus.validating,
    DeclarationStatus.paymentPending,
    DeclarationStatus.levante,
    DeclarationStatus.rejected,
    DeclarationStatus.annulled,
    DeclarationStatus.confirmed,
  ];

  const StatusFilterChips({
    super.key,
    required this.selected,
    required this.onChanged,
    this.available = defaultStatuses,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final status in available) ...[
            _Chip(
              status: status,
              selected: selected.contains(status),
              onToggle: () {
                final next = Set<DeclarationStatus>.from(selected);
                if (!next.add(status)) next.remove(status);
                onChanged(next);
              },
            ),
            const SizedBox(width: 6),
          ],
          if (selected.isNotEmpty)
            TextButton(
              onPressed: () => onChanged(const {}),
              child: const Text('Limpiar'),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final DeclarationStatus status;
  final bool selected;
  final VoidCallback onToggle;

  const _Chip({
    required this.status,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final tone = toneForStatus(status);
    final colors = StatusToneColors.of(tone);
    final backgroundColor = selected
        ? colors.background
        : AduaNextTheme.surfaceCard;
    final borderColor = selected ? colors.border : AduaNextTheme.borderSubtle;
    final textColor = selected
        ? colors.foreground
        : AduaNextTheme.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.check, size: 12),
                ),
              Text(
                status.displayName,
                style: TextStyle(
                  fontSize: 11,
                  color: textColor,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
