/// Unit tests for [TokenBucket], [TokenBucketRegistry], and the
/// [rateLimitMiddleware] shelf wrapper.
///
/// The bucket math is deterministic under a fake clock — tests drive
/// the clock explicitly so we never have to sleep.
library;

import 'dart:convert';

import 'package:aduanext_server/aduanext_server.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  group('TokenBucket', () {
    test('starts full at [capacity] and consumes one token per request',
        () {
      var now = DateTime.utc(2026, 1, 1, 0, 0, 0);
      final bucket = TokenBucket(
        capacity: 3,
        refillRate: 3,
        refillInterval: const Duration(minutes: 1),
        clock: () => now,
      );

      final first = bucket.tryConsume(now);
      expect(first.allowed, isTrue);
      expect(first.remaining, 2);

      final second = bucket.tryConsume(now);
      expect(second.allowed, isTrue);
      expect(second.remaining, 1);

      final third = bucket.tryConsume(now);
      expect(third.allowed, isTrue);
      expect(third.remaining, 0);

      final fourth = bucket.tryConsume(now);
      expect(fourth.allowed, isFalse);
      expect(fourth.remaining, 0);
      expect(fourth.retryAfter, greaterThan(Duration.zero));
    });

    test('refills proportionally over time, never exceeding capacity',
        () {
      var now = DateTime.utc(2026, 1, 1, 0, 0, 0);
      final bucket = TokenBucket(
        capacity: 10,
        refillRate: 10,
        refillInterval: const Duration(minutes: 1),
        clock: () => now,
      );

      // Drain the bucket.
      for (var i = 0; i < 10; i++) {
        bucket.tryConsume(now);
      }
      expect(bucket.tryConsume(now).allowed, isFalse);

      // Advance 30s — should award ~5 tokens.
      now = now.add(const Duration(seconds: 30));
      final decision = bucket.tryConsume(now);
      expect(decision.allowed, isTrue);
      // After consuming one, we should have ~4 left.
      expect(decision.remaining, inInclusiveRange(3, 4));

      // Advance 10 full minutes — bucket should cap at 10 (not 100).
      now = now.add(const Duration(minutes: 10));
      final refilled = bucket.tryConsume(now);
      expect(refilled.allowed, isTrue);
      expect(refilled.remaining, 9); // capacity 10 − 1 just consumed.
    });

    test('retryAfter is sensible (positive, bounded)', () {
      var now = DateTime.utc(2026, 1, 1, 0, 0, 0);
      final bucket = TokenBucket(
        capacity: 1,
        refillRate: 1,
        refillInterval: const Duration(seconds: 60),
        clock: () => now,
      );
      bucket.tryConsume(now); // drain
      final denied = bucket.tryConsume(now);
      expect(denied.allowed, isFalse);
      expect(denied.retryAfter, greaterThan(Duration.zero));
      expect(denied.retryAfter,
          lessThanOrEqualTo(const Duration(seconds: 60)));
    });
  });

  group('TokenBucketRegistry', () {
    test('separate keys get separate buckets', () {
      var now = DateTime.utc(2026, 1, 1, 0, 0, 0);
      final reg = TokenBucketRegistry(
        capacity: 2,
        refillRate: 2,
        refillInterval: const Duration(minutes: 1),
        clock: () => now,
      );

      // Drain tenant A.
      expect(reg.tryConsume('tenant:a').allowed, isTrue);
      expect(reg.tryConsume('tenant:a').allowed, isTrue);
      expect(reg.tryConsume('tenant:a').allowed, isFalse);

      // Tenant B still full.
      expect(reg.tryConsume('tenant:b').allowed, isTrue);
      expect(reg.tryConsume('tenant:b').allowed, isTrue);
      expect(reg.tryConsume('tenant:b').allowed, isFalse);

      expect(reg.keyCount, 2);
    });
  });

  group('rateLimitMiddleware', () {
    /// Build a pipeline that doesn't touch the request context (the
    /// middleware falls back to the `anonymous` key which we pin via
    /// the [keyFor] parameter in tests).
    Handler buildPipeline(TokenBucketRegistry registry, String fixedKey) {
      return const Pipeline()
          .addMiddleware(rateLimitMiddleware(
            registry: registry,
            keyFor: (_) => fixedKey,
          ))
          .addHandler((r) async => Response.ok('hi'));
    }

    test('emits X-RateLimit-* headers on success', () async {
      final registry = TokenBucketRegistry(
        capacity: 5,
        refillRate: 5,
        refillInterval: const Duration(minutes: 1),
      );
      final pipeline = buildPipeline(registry, 'tenant:t1');

      final response = await pipeline(
        Request('POST', Uri.parse('http://localhost/hit')),
      );
      expect(response.statusCode, 200);
      expect(response.headers['x-ratelimit-limit'], '5');
      expect(response.headers['x-ratelimit-remaining'], '4');
    });

    test('11th request in an empty-refill window → 429 + Retry-After',
        () async {
      // Capacity 10, refillRate 10 per minute — 11th request without
      // any time advancing MUST be rejected.
      var now = DateTime.utc(2026, 1, 1, 0, 0, 0);
      final registry = TokenBucketRegistry(
        capacity: 10,
        refillRate: 10,
        refillInterval: const Duration(minutes: 1),
        clock: () => now,
      );
      final pipeline = buildPipeline(registry, 'tenant:t-heavy');

      for (var i = 0; i < 10; i++) {
        final ok = await pipeline(
          Request('POST', Uri.parse('http://localhost/hit')),
        );
        expect(ok.statusCode, 200,
            reason: 'request ${i + 1} should succeed');
      }
      final rejected = await pipeline(
        Request('POST', Uri.parse('http://localhost/hit')),
      );
      expect(rejected.statusCode, 429);
      expect(rejected.headers['retry-after'], isNotNull);
      expect(int.parse(rejected.headers['retry-after']!),
          greaterThanOrEqualTo(1));
      final body = jsonDecode(await rejected.readAsString())
          as Map<String, dynamic>;
      expect(body['code'], 'RATE_LIMITED');
      expect(body['error'], 'rate_limited');
    });

    test('separate tenants are limited independently', () async {
      final registry = TokenBucketRegistry(
        capacity: 1,
        refillRate: 1,
        refillInterval: const Duration(minutes: 1),
      );
      final pipelineA = buildPipeline(registry, 'tenant:a');
      final pipelineB = buildPipeline(registry, 'tenant:b');

      // Tenant A uses its only token.
      expect(
        (await pipelineA(
                Request('POST', Uri.parse('http://localhost/x'))))
            .statusCode,
        200,
      );
      // Tenant A is now rate-limited.
      expect(
        (await pipelineA(
                Request('POST', Uri.parse('http://localhost/x'))))
            .statusCode,
        429,
      );
      // Tenant B still has its full token.
      expect(
        (await pipelineB(
                Request('POST', Uri.parse('http://localhost/x'))))
            .statusCode,
        200,
      );
    });
  });
}
