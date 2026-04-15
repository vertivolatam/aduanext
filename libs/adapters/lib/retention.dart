/// Retention adapters implementing [LegalHoldPort] and supporting the
/// VRTV-57 retention worker.
///
/// * [InMemoryLegalHoldAdapter] — for tests and dev runs. The
///   Postgres-backed adapter ships with the migration tool work.
library;

export 'src/retention/in_memory_legal_hold_adapter.dart';
