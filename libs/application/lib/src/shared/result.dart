/// Result<T> — a functional wrapper for expected success/failure.
///
/// Use for business-level outcomes (validation, rule violations,
/// business-layer "not found"). Infrastructure failures (DB down,
/// port unavailable) should throw exceptions — they are NOT
/// [Result.err] values.
///
/// Style: we keep this sealed-like via a private constructor + the
/// two concrete subclasses [Ok] and [Err]. Callers pattern-match on
/// them with Dart 3's `switch` / `case` expression.
library;

import 'package:meta/meta.dart';

import 'failure.dart';

/// Discriminated outcome of a use case.
@immutable
sealed class Result<T> {
  const Result._();

  /// Convenience constructors for ergonomics at call sites:
  ///
  ///   return Result.ok(entity);
  ///   return Result.err(Failure(...));
  const factory Result.ok(T value) = Ok<T>;
  const factory Result.err(Failure failure) = Err<T>;

  /// `true` iff this is an [Ok].
  bool get isOk => this is Ok<T>;

  /// `true` iff this is an [Err].
  bool get isErr => this is Err<T>;

  /// Returns the success value, or `null` for an [Err].
  T? get valueOrNull {
    final self = this;
    return self is Ok<T> ? self.value : null;
  }

  /// Returns the failure, or `null` for an [Ok].
  Failure? get failureOrNull {
    final self = this;
    return self is Err<T> ? self.failure : null;
  }

  /// Functor map — transform the success value, leaving an [Err]
  /// untouched.
  Result<U> map<U>(U Function(T value) transform) {
    final self = this;
    return switch (self) {
      Ok<T>(:final value) => Result.ok(transform(value)),
      Err<T>(:final failure) => Result.err(failure),
    };
  }
}

/// Successful outcome.
@immutable
final class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value) : super._();

  @override
  bool operator ==(Object other) =>
      other is Ok<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Ok($value)';
}

/// Failed outcome.
@immutable
final class Err<T> extends Result<T> {
  final Failure failure;
  const Err(this.failure) : super._();

  @override
  bool operator ==(Object other) =>
      other is Err<T> && other.failure == failure;

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'Err($failure)';
}
