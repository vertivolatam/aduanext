/// Shared AduaNext UI package — Atomic Design widgets y tema.
///
/// Presentación pura: puede depender de `aduanext_domain` (value objects),
/// nunca de DTOs de API ni de providers de Riverpod (Explicit Architecture).
library;

// Theme
export 'src/theme/aduanext_theme.dart';

// Atoms
export 'src/atoms/classification_confidence_bar.dart';
export 'src/atoms/declaration_status_semaphore.dart';
export 'src/atoms/hs_code_chip.dart';
export 'src/atoms/kpi_card.dart';
export 'src/atoms/risk_score_badge.dart';
export 'src/atoms/tariff_rate_cell.dart';
export 'src/atoms/timeline_dot.dart';

// Molecules
export 'src/molecules/kpi_row.dart';
export 'src/molecules/status_filter_chips.dart';

// Organisms
export 'src/organisms/sidebar_panel.dart';
export 'src/organisms/sidebar_rail.dart';

// Templates
export 'src/templates/dashboard_layout.dart';
