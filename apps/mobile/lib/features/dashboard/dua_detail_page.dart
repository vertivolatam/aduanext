/// DuaDetailPage — drill-down on a single dispatch.
///
/// Reads [dispatchDetailProvider] for the declaration ID from the
/// route param. Renders:
///   * Header with declarationId + status pill + risk score
///   * Commercial description + exporter
///   * Full DuaTimeline (expanded variant)
///   * Rejected panel (if applicable)
///   * Audit events feed (scrolls independently when long)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../shared/api/api_exception.dart';
import '../../shared/api/dispatch_dto.dart';
import '../../shared/theme/aduanext_theme.dart';
import '../../shared/ui/atoms/declaration_status_semaphore.dart';
import '../../shared/ui/atoms/risk_score_badge.dart';
import '../../shared/ui/organisms/dua_rejected_panel.dart';
import '../../shared/ui/organisms/dua_timeline.dart';
import 'dashboard_providers.dart';

class DuaDetailPage extends ConsumerWidget {
  final String declarationId;
  const DuaDetailPage({super.key, required this.declarationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(
      dispatchDetailProvider(DispatchDetailQuery(declarationId)),
    );

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _DetailError(
        error: err,
        declarationId: declarationId,
      ),
      data: (detail) => _DetailBody(detail: detail),
    );
  }
}

class _DetailError extends StatelessWidget {
  final Object error;
  final String declarationId;
  const _DetailError({required this.error, required this.declarationId});

  @override
  Widget build(BuildContext context) {
    final message = error is ApiException
        ? (error as ApiException).message
        : 'No se pudo cargar la DUA.';
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const BackButton(),
            Text(
              declarationId,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ]),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(color: AduaNextTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final DispatchDetail detail;
  const _DetailBody({required this.detail});

  @override
  Widget build(BuildContext context) {
    final s = detail.summary;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              IconButton(
                onPressed: () => context.canPop() ? context.pop() : null,
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  s.declarationId,
                  style: Theme.of(context).textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DeclarationStatusSemaphore(status: s.status),
              const SizedBox(width: 8),
              RiskScoreBadge(score: s.riskScore),
            ]),
            const SizedBox(height: 8),
            Text(
              s.commercialDescription,
              style: const TextStyle(color: AduaNextTheme.textPrimary),
            ),
            if (s.exporterName != null) ...[
              const SizedBox(height: 4),
              Text(
                'Exportador: ${s.exporterName} (${s.exporterCode})',
                style:
                    const TextStyle(color: AduaNextTheme.textSecondary),
              ),
            ],
            const SizedBox(height: 24),

            // Main timeline
            Text(
              'Línea de tiempo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AduaNextTheme.surfaceCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AduaNextTheme.borderSubtle),
              ),
              child: DuaTimeline(dispatch: s),
            ),

            if (s.atenaError != null) ...[
              const SizedBox(height: 24),
              Text(
                'Error ATENA',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              DuaRejectedPanel(error: s.atenaError!),
            ],

            const SizedBox(height: 24),
            Text(
              'Audit trail (${detail.auditEvents.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (detail.auditEvents.isEmpty)
              const _AuditEmpty()
            else
              for (final ev in detail.auditEvents) _AuditRow(event: ev),
          ],
        ),
      ),
    );
  }
}

class _AuditEmpty extends StatelessWidget {
  const _AuditEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AduaNextTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AduaNextTheme.borderSubtle),
      ),
      child: const Text(
        'No hay eventos registrados.',
        style: TextStyle(color: AduaNextTheme.textSecondary),
      ),
    );
  }
}

class _AuditRow extends StatelessWidget {
  final DispatchAuditEvent event;
  const _AuditRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('yyyy-MM-dd HH:mm').format(event.at.toLocal());
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AduaNextTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AduaNextTheme.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 8,
            height: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AduaNextTheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.action,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AduaNextTheme.textPrimary,
                  ),
                ),
                Text(
                  'por ${event.actorName} · $dateStr',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AduaNextTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
