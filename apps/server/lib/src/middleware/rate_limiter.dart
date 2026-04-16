/// Per-tenant token-bucket rate limiter for the dispatch submit
/// endpoint.
///
/// Strategy: one bucket per tenant (keyed off the `X-Tenant-Id` carried
/// through the [RequestContext]). IP-based keying is intentionally not
/// used — agents in a corporate NAT share an egress IP and throttling
/// them together would effectively lock out an agency.
///
/// Design notes (explicitly called out so future contributors don't
/// "fix" them into something worse):
///
/// * In-process, single-node. A multi-replica production deployment
///   will eventually want Redis + sliding window; we will revisit when
///   horizontal scale is planned (there is a separate issue for that).
///   For the current deployment (single Kubernetes pod, single-node
///   postgres), in-process is correct.
/// * Per-minute refill. The [capacity] is the burst size; [refillRate]
///   tokens arrive every [refillInterval]. Defaults: 10 tokens, 10/min.
/// * Non-fair: we don't queue on exhaustion, we reject with 429 — the
///   client can retry with [Retry-After].
/// * Bucket eviction: buckets never clear on their own. Production
///   tenant count is bounded (hundreds) so the memory cost is trivial.
///   If that changes we can add a periodic reaper.
///
/// Headers emitted on every pass-through response:
/// * `X-RateLimit-Limit: <capacity>` — bucket size.
/// * `X-RateLimit-Remaining: <count>` — tokens after this request.
///
/// On rejection:
/// * `Retry-After: <seconds>` — seconds until the next token arrives.
library;

import 'dart:convert';
import 'dart:math';

import 'package:shelf/shelf.dart';

import '../http/error_mapping.dart';
import '../http/request_context.dart';

/// A single token bucket. Tokens refill continuously based on
/// [refillRate] / [refillInterval]; a request succeeds when at least
/// one token is available. State is replayed lazily on each access so
/// we don't need a timer per bucket.
class TokenBucket {
  final int capacity;
  final int refillRate;
  final Duration refillInterval;

  double _tokens;
  DateTime _lastRefill;

  TokenBucket({
    required this.capacity,
    required this.refillRate,
    required this.refillInterval,
    required DateTime Function() clock,
  })  : _tokens = capacity.toDouble(),
        _lastRefill = clock();

  /// Attempt to consume one token. Returns a [TokenBucketDecision]
  /// describing the outcome so the middleware can emit headers.
  TokenBucketDecision tryConsume(DateTime now) {
    // Lazy refill: award the fraction of tokens that would have been
    // produced since [_lastRefill]. We cap at [capacity] so an
    // extended idle period does not turn into an unlimited burst.
    final elapsed = now.difference(_lastRefill);
    if (elapsed > Duration.zero) {
      final ratio = elapsed.inMicroseconds /
          refillInterval.inMicroseconds;
      _tokens = min(capacity.toDouble(), _tokens + ratio * refillRate);
      _lastRefill = now;
    }

    if (_tokens >= 1.0) {
      _tokens -= 1.0;
      return TokenBucketDecision(
        allowed: true,
        remaining: _tokens.floor(),
        retryAfter: Duration.zero,
      );
    }
    // Seconds until the next token arrives.
    final missing = 1.0 - _tokens;
    final microsPerToken =
        refillInterval.inMicroseconds / refillRate;
    final waitMicros = (missing * microsPerToken).ceil();
    return TokenBucketDecision(
      allowed: false,
      remaining: 0,
      retryAfter: Duration(microseconds: waitMicros),
    );
  }
}

class TokenBucketDecision {
  final bool allowed;
  final int remaining;
  final Duration retryAfter;

  const TokenBucketDecision({
    required this.allowed,
    required this.remaining,
    required this.retryAfter,
  });
}

/// Keyed collection of buckets.
class TokenBucketRegistry {
  final int capacity;
  final int refillRate;
  final Duration refillInterval;
  final DateTime Function() _clock;
  final Map<String, TokenBucket> _buckets = {};

  TokenBucketRegistry({
    required this.capacity,
    required this.refillRate,
    required this.refillInterval,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  TokenBucketDecision tryConsume(String key) {
    final bucket = _buckets.putIfAbsent(
      key,
      () => TokenBucket(
        capacity: capacity,
        refillRate: refillRate,
        refillInterval: refillInterval,
        clock: _clock,
      ),
    );
    return bucket.tryConsume(_clock());
  }

  /// Number of distinct keys ever seen. Exposed for tests + metrics.
  int get keyCount => _buckets.length;
}

/// Middleware factory. [keyFor] chooses the bucket for a request;
/// default is the [RequestContext.selectedTenantId], falling back to
/// a stable `anonymous` key (which should never happen on a protected
/// route but we fail-safely rather than NPE).
Middleware rateLimitMiddleware({
  required TokenBucketRegistry registry,
  String Function(Request)? keyFor,
}) {
  final effectiveKeyFn = keyFor ?? _tenantKeyFromContext;
  return (Handler inner) {
    return (Request request) async {
      final key = effectiveKeyFn(request);
      final decision = registry.tryConsume(key);
      if (!decision.allowed) {
        final retryAfterSeconds =
            max(1, decision.retryAfter.inSeconds);
        return Response(
          429,
          body: jsonEncode({
            'error': 'rate_limited',
            'code': DispatchErrorCodes.rateLimited,
            'message': 'Too many requests for this tenant; retry '
                'in $retryAfterSeconds s',
            'request_id': request.requestContextOrNull?.requestId ??
                'req_unknown',
          }),
          headers: {
            'content-type': 'application/json',
            'retry-after': '$retryAfterSeconds',
            'x-ratelimit-limit': '${registry.capacity}',
            'x-ratelimit-remaining': '0',
          },
        );
      }

      final response = await inner(request);
      return response.change(headers: {
        'x-ratelimit-limit': '${registry.capacity}',
        'x-ratelimit-remaining': '${decision.remaining}',
      });
    };
  };
}

String _tenantKeyFromContext(Request request) {
  final ctx = request.requestContextOrNull;
  final tenantId = ctx?.selectedTenantId;
  if (tenantId == null || tenantId.isEmpty) {
    return 'anonymous';
  }
  return 'tenant:$tenantId';
}
