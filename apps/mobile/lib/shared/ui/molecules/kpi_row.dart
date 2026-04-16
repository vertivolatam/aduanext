/// Molecule: the 4-column KPI row at the top of the dashboard.
///
/// Takes a summary of counts keyed by [StatusTone] bucket — callers
/// (VRTV-85 dashboard page) compute the buckets from the dispatch list
/// using the same `toneForStatus` helper as the list rows so the KPI
/// row and the pills stay in sync.
///
/// Responsive: falls back to 2x2 on narrow viewports (< 480px) so the
/// header survives the onboarding wizard's right sidebar and mobile
/// browsers (even though we target tablets).
library;

import 'package:flutter/material.dart';

import '../atoms/declaration_status_semaphore.dart' show StatusTone;
import '../atoms/kpi_card.dart';

/// Count summary for the 4 KPI tiles. Each field is the number of
/// DUAs currently sitting in that bucket.
class KpiSummary {
  /// Everything that is not yet in a terminal state. Includes draft,
  /// validating, levante, etc. — essentially "DUAs en el sistema".
  final int activas;

  /// Count of DUAs with `status.tone == verde` (levante family).
  final int levante;

  /// Count with `status.tone == amber` (in process).
  final int enProceso;

  /// Count with `status.tone == rojo` (rejected / annulled).
  final int requiereAccion;

  const KpiSummary({
    required this.activas,
    required this.levante,
    required this.enProceso,
    required this.requiereAccion,
  });

  const KpiSummary.zero()
      : activas = 0,
        levante = 0,
        enProceso = 0,
        requiereAccion = 0;
}

/// 4-column KPI row.
class KpiRow extends StatelessWidget {
  final KpiSummary summary;

  /// Fires when a KPI is tapped, so the parent can filter the list by
  /// the selected bucket. `null` means "Activas" (clear filter).
  final ValueChanged<StatusTone?>? onTap;

  const KpiRow({super.key, required this.summary, this.onTap});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width < 480 ? 2 : 4;

    // Build the 4 tiles once; the layout picks which scaffold to use.
    final tiles = [
      KpiCard(
        label: 'Activas',
        value: summary.activas,
        onTap: onTap == null ? null : () => onTap!(null),
      ),
      KpiCard(
        label: 'Levante',
        value: summary.levante,
        tone: StatusTone.verde,
        onTap: onTap == null ? null : () => onTap!(StatusTone.verde),
      ),
      KpiCard(
        label: 'En proceso',
        value: summary.enProceso,
        tone: StatusTone.amber,
        onTap: onTap == null ? null : () => onTap!(StatusTone.amber),
      ),
      KpiCard(
        label: 'Requiere acción',
        value: summary.requiereAccion,
        tone: StatusTone.rojo,
        onTap: onTap == null ? null : () => onTap!(StatusTone.rojo),
      ),
    ];

    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: tiles,
    );
  }
}
