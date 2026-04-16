/// Riverpod wiring for the RIMM classifier.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/api/api_providers.dart';
import 'classification_client.dart';
import 'classification_dto.dart';

/// The client used to fetch suggestions. Swaps in [FakeClassificationClient]
/// when `ApiConfig.useFake` is true so offline dev + widget tests
/// exercise deterministic seed data.
final classificationClientProvider = Provider<ClassificationClient>((ref) {
  final config = ref.watch(apiConfigProvider);
  if (config.useFake) {
    final fake = FakeClassificationClient();
    ref.onDispose(fake.close);
    return fake;
  }
  final token = ref.watch(bearerTokenProvider);
  final client = HttpClassificationClient(
    config: config,
    tokenProvider: token,
  );
  ref.onDispose(client.close);
  return client;
});

/// Current search state for the classifier drawer.
class ClassifierQuery {
  final String description;
  final ClassificationSearchMode mode;

  const ClassifierQuery({
    required this.description,
    required this.mode,
  });

  @override
  bool operator ==(Object other) =>
      other is ClassifierQuery &&
      other.description == description &&
      other.mode == mode;

  @override
  int get hashCode => Object.hash(description, mode);
}

/// Mutable current query. Set by the drawer on submit; the suggestions
/// provider reacts.
final classifierQueryProvider = StateProvider<ClassifierQuery?>((ref) => null);

/// Fetch suggestions for the current query. Returns `null` (via the
/// `AsyncValue` default) when no query has been submitted yet.
final classificationSuggestionsProvider =
    FutureProvider<ClassificationSuggestResponse?>((ref) async {
  final query = ref.watch(classifierQueryProvider);
  if (query == null) return null;
  final client = ref.watch(classificationClientProvider);
  return client.suggest(
    query.description,
    mode: query.mode,
  );
});
