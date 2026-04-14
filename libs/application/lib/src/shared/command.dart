/// CQRS command + handler contracts.
///
/// A [Command] is an intent to mutate state. It carries all the
/// information required to perform the mutation and nothing else. The
/// matching [CommandHandler] validates it, executes the use case, and
/// returns a [Result].
///
/// Queries (reads) follow the same shape but live in query files — we
/// keep them type-separate so a casual reader can tell read from write
/// at a glance.
library;

import 'package:meta/meta.dart';

import 'result.dart';

/// Marker super-type for commands (write intents).
///
/// [TResult] is the type returned inside the [Result] on success —
/// typically the freshly-created/updated entity, or `void` for
/// fire-and-forget commands.
@immutable
abstract class Command<TResult> {
  const Command();
}

/// Handler that validates and executes a [Command].
///
/// Implementations MUST:
/// - Validate the command and return `Result.err(Failure)` on invalid
///   input (do NOT throw for expected business errors).
/// - Throw for infrastructure failures (DB unreachable, port
///   unavailable). The boundary (Serverpod endpoint, CLI, etc.) is
///   responsible for catching those.
/// - Be idempotent where the domain permits — the same command
///   executed twice should either produce the same effect once or
///   return a clear failure on the second attempt.
abstract class CommandHandler<TCommand extends Command<TResult>, TResult> {
  Future<Result<TResult>> handle(TCommand command);
}
