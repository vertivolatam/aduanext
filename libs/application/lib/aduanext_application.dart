/// AduaNext Application Layer — Use Cases + CQRS infrastructure.
///
/// Depends only on `aduanext_domain`. Adapters and primary adapters
/// (apps/server) depend on this package; never the other way around.
///
/// ## Conventions
///
/// - CQRS: every write path is a [Command] handled by a
///   [CommandHandler<TCommand, TResult>]; every read is a query (same
///   pattern, separate file).
/// - Result: use cases return [Result<T>] for expected business errors
///   (validation, rule violations). Infrastructure failures (DB down,
///   port unavailable) throw typed exceptions — they are NOT business
///   errors and should be caught at the boundary (Serverpod endpoint).
/// - Vertical slice layout: each feature owns its own folder under
///   `lib/src/<feature>/`. Shared CQRS + Result primitives live under
///   `lib/src/shared/`.
library;

// Shared CQRS + Result infrastructure.
export 'src/shared/command.dart';
export 'src/shared/failure.dart';
export 'src/shared/result.dart';

// Classification feature slice.
export 'src/classification/record_classification_command.dart';
export 'src/classification/record_classification_failure.dart';
export 'src/classification/record_classification_handler.dart';

// Submission feature slice (SOP-B05, North Star use case).
export 'src/submission/submit_declaration_command.dart';
export 'src/submission/submit_declaration_failure.dart';
export 'src/submission/submit_declaration_handler.dart';
