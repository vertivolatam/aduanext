/// Retention adapters implementing [LegalHoldPort] and supporting the
/// VRTV-57 retention worker.
///
/// * [InMemoryLegalHoldAdapter] — for tests and dev runs.
/// * [PostgresLegalHoldAdapter] — for the Serverpod server deploy
///   (VRTV-73). Assumes audit-log migration 0002 has already installed
///   `current_app_tenant()` / `set_app_tenant()` + the `aduanext_app`
///   non-bypassing role (they are reused across tables).
library;

export 'src/retention/in_memory_legal_hold_adapter.dart';
export 'src/retention/postgres_legal_hold_adapter.dart';
