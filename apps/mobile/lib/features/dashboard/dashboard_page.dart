/// DashboardPage — the landing screen for agents / pymes / admins.
///
/// Composition (per `08-monitoring-dashboard.html` mockup):
///   * Header (title + search + "Nueva DUA" CTA)
///   * KPI row (4 tiles, tone-tinted)
///   * View tabs (Lista | Timeline | Kanban — only Lista is wired
///     today; the others render a "Próximamente" placeholder.)
///   * Filter chip row (status multi-select + date range + clear)
///   * Virtualized DUA list
///
/// State lives in `dashboard_providers.dart`; the page is a
/// ConsumerWidget that watches the providers and pumps the results
/// into the atoms/molecules/organisms from VRTV-84.
library;

import 'package:aduanext_domain/aduanext_domain.dart' hide Container;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/api/api_exception.dart';
import '../../shared/api/dispatch_dto.dart';
import '../../shared/api/dispatch_stream_providers.dart';
import '../../shared/theme/aduanext_theme.dart';
import '../../shared/ui/atoms/declaration_status_semaphore.dart';
import '../../shared/ui/atoms/live_indicator.dart';
import '../../shared/ui/molecules/dua_list_item.dart';
import '../../shared/ui/molecules/kpi_row.dart';
import '../../shared/ui/molecules/status_filter_chips.dart';
import '../../shared/ui/organisms/dua_rejected_panel.dart';
import '../../shared/ui/organisms/dua_timeline.dart';
import 'dashboard_filters.dart';
import 'dashboard_providers.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Wire the polling fallback — invoked when the backend returns
    // 404/501 and the stream client flips to polling mode.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(dispatchStreamClientProvider).setPollingTick((_) {
        if (!mounted) return;
        ref.invalidate(dispatchesListProvider);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(dashboardFiltersProvider);
    final kpi = ref.watch(dashboardKpiSummaryProvider);
    final listAsync = ref.watch(dispatchesListProvider);

    // React to live SSE updates: every event invalidates the list
    // so `dispatchesListProvider` refetches and the UI reflects the
    // new state. A future optimization (tracked as VRTV-87) can
    // mutate the list in-place from the `patch` field without
    // hitting the backend — for now the refetch is cheap.
    ref.listen<AsyncValue<DispatchUpdate>>(
      dispatchStreamUpdatesProvider,
      (_, next) {
        if (next is AsyncData<DispatchUpdate>) {
          ref.invalidate(dispatchesListProvider);
        }
      },
    );

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(filters: filters),
            const SizedBox(height: 16),
            KpiRow(
              summary: kpi,
              onTap: (tone) => _onKpiTap(ref, tone),
            ),
            const SizedBox(height: 16),
            const _ViewTabs(),
            const SizedBox(height: 12),
            StatusFilterChips(
              selected: filters.statuses,
              onChanged: (next) {
                ref.read(dashboardFiltersProvider.notifier).state =
                    filters.copyWith(statuses: next);
                ref.read(dashboardPageProvider.notifier).state = 0;
              },
            ),
            const SizedBox(height: 16),
            _DashboardBody(listAsync: listAsync),
          ],
        ),
      ),
    );
  }

  /// Translates a KPI tap into a status filter. Null clears.
  void _onKpiTap(WidgetRef ref, StatusTone? tone) {
    final current = ref.read(dashboardFiltersProvider);
    final statuses = tone == null
        ? const <DeclarationStatus>{}
        : StatusFilterChips.defaultStatuses
            .where((s) => toneForStatus(s) == tone)
            .toSet();
    ref.read(dashboardFiltersProvider.notifier).state =
        current.copyWith(statuses: statuses);
    ref.read(dashboardPageProvider.notifier).state = 0;
  }
}

// ─── Header ──────────────────────────────────────────────────────

class _Header extends ConsumerStatefulWidget {
  final DashboardFilters filters;
  const _Header({required this.filters});

  @override
  ConsumerState<_Header> createState() => _HeaderState();
}

class _HeaderState extends ConsumerState<_Header> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.filters.exporterSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + live indicator: Wrap so the indicator falls onto a
        // second line under narrow viewports instead of overflowing.
        Wrap(
          spacing: 12,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Monitoreo DUAs',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const LiveIndicator(),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
        SizedBox(
          width: 200,
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              hintText: 'Buscar exportador...',
              prefixIcon: Icon(Icons.search, size: 16),
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            style: const TextStyle(fontSize: 11),
            onChanged: (value) {
              ref.read(dashboardFiltersProvider.notifier).state =
                  widget.filters.copyWith(exporterSearch: value);
              ref.read(dashboardPageProvider.notifier).state = 0;
            },
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          // VRTV-87 wires the stepper skeleton; full step content
          // lands with VRTV-88 + VRTV-89.
          onPressed: () => context.push('/dua-form/new'),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Nueva DUA'),
        ),
          ],
        ),
      ],
    );
  }
}

// ─── View tabs (Lista / Timeline / Kanban) ───────────────────────

class _ViewTabs extends StatelessWidget {
  const _ViewTabs();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AduaNextTheme.borderSubtle),
        ),
      ),
      child: Row(
        children: [
          _Tab(label: 'Lista', active: true),
          _Tab(label: 'Timeline', dimmed: true),
          _Tab(label: 'Kanban', dimmed: true),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final bool dimmed;
  const _Tab({required this.label, this.active = false, this.dimmed = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: active
          ? const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AduaNextTheme.primary, width: 2),
              ),
            )
          : null,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: active
              ? AduaNextTheme.primary
              : dimmed
                  ? AduaNextTheme.textSecondary
                  : AduaNextTheme.textPrimary,
          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

// ─── Body: list + loading / error / empty states ──────────────────

class _DashboardBody extends ConsumerWidget {
  final AsyncValue<DispatchListResponse> listAsync;

  const _DashboardBody({required this.listAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return listAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _ErrorState(error: error, ref: ref),
      data: (response) => response.items.isEmpty
          ? const _EmptyState()
          : _DispatchList(response: response),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          'No hay DUAs que coincidan con los filtros.',
          style: TextStyle(color: AduaNextTheme.textSecondary),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Object error;
  final WidgetRef ref;

  const _ErrorState({required this.error, required this.ref});

  @override
  Widget build(BuildContext context) {
    final message = error is ApiException
        ? (error as ApiException).message
        : 'Error inesperado al cargar DUAs.';
    final isNotImplemented = error is NotImplementedApiException;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isNotImplemented ? Icons.construction : Icons.error_outline,
              size: 48,
              color: AduaNextTheme.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AduaNextTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            if (!isNotImplemented)
              ElevatedButton.icon(
                onPressed: () {
                  // Poking the page provider invalidates the list
                  // future by re-reading it.
                  ref.invalidate(dispatchesListProvider);
                },
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('Reintentar'),
              ),
          ],
        ),
      ),
    );
  }
}

class _DispatchList extends ConsumerWidget {
  final DispatchListResponse response;
  const _DispatchList({required this.response});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(dashboardPageProvider);
    final pageSize = ref.watch(dashboardPageSizeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Virtualized list. shrinkWrap so it plays nice inside the
        // outer SingleChildScrollView; the list itself doesn't scroll
        // because the whole page scrolls as one unit — fine at page
        // size 50 (50 * 90px ≈ 4.5K px max, browser handles cleanly).
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: response.items.length,
          itemBuilder: (_, i) => _DispatchRow(dispatch: response.items[i]),
        ),
        const SizedBox(height: 12),
        _Pagination(
          response: response,
          page: page,
          pageSize: pageSize,
          onNext: response.hasMore
              ? () => ref.read(dashboardPageProvider.notifier).state =
                  page + 1
              : null,
          onPrev: page > 0
              ? () => ref.read(dashboardPageProvider.notifier).state =
                  page - 1
              : null,
        ),
      ],
    );
  }
}

class _DispatchRow extends StatelessWidget {
  final DispatchSummary dispatch;
  const _DispatchRow({required this.dispatch});

  @override
  Widget build(BuildContext context) {
    // Decide the "right-hint" message per status tone so the list
    // row reads like the mockup (Levante → "Retiro disponible",
    // Validating → "En ATENA desde hace Nh", Rejected → none in main
    // row; the error card below carries the CTA).
    final tone = toneForStatus(dispatch.status);
    final hoursSince =
        dispatch.hoursSinceUpdate(DateTime.now().toUtc());

    final String? rightHint = switch (tone) {
      StatusTone.verde => 'Retiro disponible',
      StatusTone.amber => 'En ATENA desde hace ${hoursSince}h',
      StatusTone.rojo => null,
      StatusTone.gris => 'Actualizado hace ${hoursSince}h',
    };
    final String rightSubtitle =
        'Aduana ${dispatch.officeOfDispatchExportCode}';

    final Widget? footer = switch (tone) {
      StatusTone.verde => DuaTimeline(
          dispatch: dispatch,
          variant: TimelineVariant.expanded,
        ),
      StatusTone.amber => DuaTimeline(
          dispatch: dispatch,
          variant: TimelineVariant.compact,
        ),
      StatusTone.rojo => dispatch.atenaError == null
          ? null
          : DuaRejectedPanel(
              error: dispatch.atenaError!,
              onRectify: () => _onRectify(context, dispatch.declarationId),
            ),
      StatusTone.gris => null,
    };

    return DuaListItem(
      dispatch: dispatch,
      rightHint: rightHint,
      rightSubtitle: rightSubtitle,
      footer: footer,
      onTap: () => context.push('/dispatches/${dispatch.declarationId}'),
    );
  }

  void _onRectify(BuildContext context, String id) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Rectificación estará disponible en VRTV-48'),
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  final DispatchListResponse response;
  final int page;
  final int pageSize;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _Pagination({
    required this.response,
    required this.page,
    required this.pageSize,
    this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final from = page * pageSize + 1;
    final to = from + response.items.length - 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${response.total == 0 ? 0 : from}–$to de ${response.total}',
          style: const TextStyle(
            color: AduaNextTheme.textSecondary,
            fontSize: 11,
          ),
        ),
        Row(
          children: [
            IconButton(
              tooltip: 'Página anterior',
              icon: const Icon(Icons.chevron_left),
              onPressed: onPrev,
            ),
            IconButton(
              tooltip: 'Página siguiente',
              icon: const Icon(Icons.chevron_right),
              onPressed: onNext,
            ),
          ],
        ),
      ],
    );
  }
}

