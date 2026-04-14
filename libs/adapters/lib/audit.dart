/// Audit log adapters implementing `AuditLogPort`.
///
/// * [AuditChainHasher] — pure SHA-256 chain primitive.
/// * [InMemoryAuditLogAdapter] — for tests and dev runs.
/// * [SqliteAuditLogAdapter] — for mobile / desktop standalone deploys.
///
/// A PostgreSQL adapter (for the Serverpod server) is intentionally out
/// of scope for this iteration — see VRTV-52 description.
library;

export 'src/audit/audit_chain_hasher.dart';
export 'src/audit/audit_event_extensions.dart';
export 'src/audit/in_memory_audit_log_adapter.dart';
export 'src/audit/sqlite_audit_log_adapter.dart';
