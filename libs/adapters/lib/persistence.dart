/// Persistence adapters for domain aggregates other than AuditEvent.
///
/// * [InMemoryDeclarationRepositoryAdapter] — for tests and dev runs.
/// The Postgres adapter lands in a later cycle.
library;

export 'src/persistence/in_memory_declaration_repository_adapter.dart';
