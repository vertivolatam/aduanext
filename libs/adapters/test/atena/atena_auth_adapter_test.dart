/// Unit tests for [AtenaAuthAdapter].
///
/// Strategy: spin up an in-process gRPC server with a controllable
/// [FakeAuthService], point a real [AtenaAuthAdapter] at it, and drive the
/// adapter's public methods through success / failure / edge-case branches.
///
/// Regression coverage for PR #4 CodeRabbit fixes:
/// - C1: clientId fallback (credentials.clientId ?? defaultClientId)
/// - C2: empty-token guard — _lastCredentials is NOT persisted when the
///       sidecar answers `success=true` but `token=''`.
/// - C5: `isAuthenticated` swallows GrpcError and returns false (but would
///       log via developer.log; we assert the false-return contract).
/// - C10: fresh stub on each access — we verify that after shutdown() the
///       adapter surfaces StateError rather than a cached-channel gRPC error.
library;

import 'package:aduanext_adapters/adapters.dart';
import 'package:aduanext_domain/domain.dart';
import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';
import 'package:test/test.dart';

import 'package:aduanext_adapters/src/generated/hacienda.pb.dart';

import '../helpers/fake_services.dart';
import '../helpers/in_process_grpc_server.dart';

void main() {
  group('AtenaAuthAdapter', () {
    late FakeAuthService fake;
    late InProcessGrpcTestHarness harness;
    late AtenaAuthAdapter adapter;

    setUp(() async {
      fake = FakeAuthService();
      harness = await InProcessGrpcTestHarness.start([fake]);
      adapter = AtenaAuthAdapter(
        channelManager: harness.channelManager,
        defaultClientId: 'atena-default',
      );
    });

    tearDown(() async {
      await harness.stop();
    });

    const creds = Credentials(
      idType: 'CED_FISICA',
      idNumber: '0-0000-0000',
      password: 'pw',
      clientId: 'atena-cli',
    );

    test('authenticate() returns AuthToken on success', () async {
      fake.onAuthenticate = (_) =>
          AuthenticateResponse(success: true, message: 'welcome');
      fake.onGetAccessToken = (_) => GetAccessTokenResponse(
            token: 'abc.def.ghi',
            tokenType: 'Bearer',
            expiresInSeconds: Int64(3600),
          );

      final token = await adapter.authenticate(creds);

      expect(token.accessToken, 'abc.def.ghi');
      expect(token.tokenType, 'Bearer');
      expect(token.expiresInSeconds, 3600);
      // isAuthenticated contract: the adapter should now be able to refresh
      // using the persisted _lastCredentials.
      expect(fake.lastAuthenticate?.clientId, 'atena-cli');
    });

    test('authenticate() falls back to defaultClientId when creds has none',
        () async {
      const credsNoClient = Credentials(
        idType: 'CED_FISICA',
        idNumber: '0-0000-0000',
        password: 'pw',
      );
      fake.onAuthenticate = (_) => AuthenticateResponse(success: true);
      fake.onGetAccessToken = (_) => GetAccessTokenResponse(
            token: 't',
            expiresInSeconds: Int64(60),
          );

      await adapter.authenticate(credsNoClient);

      expect(fake.lastAuthenticate?.clientId, 'atena-default');
      expect(fake.lastGetAccessToken?.clientId, 'atena-default');
    });

    test('authenticate() throws AuthenticationException on success=false',
        () async {
      fake.onAuthenticate = (_) => AuthenticateResponse(
            success: false,
            message: 'Invalid credentials',
            errorCode: 'INVALID_GRANT',
          );

      await expectLater(
        adapter.authenticate(creds),
        throwsA(
          isA<AuthenticationException>()
              .having((e) => e.message, 'message', contains('Invalid'))
              .having((e) => e.vendorCode, "vendorCode", 'INVALID_GRANT'),
        ),
      );
    });

    test(
      'C2 regression: authenticate() throws when tokenResponse.token is empty '
      'and DOES NOT persist credentials',
      () async {
        fake.onAuthenticate = (_) => AuthenticateResponse(success: true);
        fake.onGetAccessToken = (_) => GetAccessTokenResponse(token: '');

        await expectLater(
          adapter.authenticate(creds),
          throwsA(
            isA<AuthenticationException>().having(
              (e) => e.message,
              'message',
              contains('empty access token'),
            ),
          ),
        );

        // Follow-up: refreshToken() must NOT be able to lean on cached
        // credentials — it falls back to defaultClientId only.
        fake.onGetAccessToken = (req) {
          return GetAccessTokenResponse(
            token: req.clientId.isNotEmpty ? 'refreshed' : '',
            expiresInSeconds: Int64(10),
          );
        };
        // refreshToken() will use defaultClientId only — confirm.
        final refreshed = await adapter.refreshToken();
        expect(refreshed.accessToken, 'refreshed');
        expect(fake.lastGetAccessToken?.clientId, 'atena-default');
      },
    );

    test('authenticate() wraps GrpcError as AuthenticationException',
        () async {
      fake.onAuthenticate = (_) =>
          throw GrpcError.unavailable('sidecar down');

      await expectLater(
        adapter.authenticate(creds),
        throwsA(
          isA<AuthenticationException>()
              .having((e) => e.vendorCode, "vendorCode", 'UNAVAILABLE'),
        ),
      );
    });

    test('refreshToken() returns a fresh AuthToken', () async {
      fake.onGetAccessToken = (_) => GetAccessTokenResponse(
            token: 'new.token',
            tokenType: '', // empty -> adapter must default to 'Bearer'
            expiresInSeconds: Int64(120),
          );

      final token = await adapter.refreshToken();
      expect(token.accessToken, 'new.token');
      expect(token.tokenType, 'Bearer');
      expect(token.expiresInSeconds, 120);
    });

    test(
      'refreshToken() throws AuthenticationException when token is empty',
      () async {
        fake.onGetAccessToken = (_) => GetAccessTokenResponse(token: '');

        await expectLater(
          adapter.refreshToken(),
          throwsA(
            isA<AuthenticationException>().having(
              (e) => e.message,
              'message',
              contains('No active session'),
            ),
          ),
        );
      },
    );

    test('refreshToken() wraps GrpcError', () async {
      fake.onGetAccessToken = (_) =>
          throw GrpcError.deadlineExceeded('slow sidecar');

      await expectLater(
        adapter.refreshToken(),
        throwsA(
          isA<AuthenticationException>()
              .having((e) => e.vendorCode, "vendorCode", 'DEADLINE_EXCEEDED'),
        ),
      );
    });

    test('isAuthenticated returns true when sidecar reports authenticated',
        () async {
      fake.onIsAuthenticated = (_) =>
          IsAuthenticatedResponse(authenticated: true);

      expect(await adapter.isAuthenticated, isTrue);
    });

    test(
      'C5 regression: isAuthenticated swallows GrpcError and returns false',
      () async {
        fake.onIsAuthenticated = (_) =>
            throw GrpcError.internal('boom');

        expect(await adapter.isAuthenticated, isFalse);
      },
    );

    test('invalidate() clears _lastCredentials on success', () async {
      // First authenticate to seed _lastCredentials.
      fake.onAuthenticate = (_) => AuthenticateResponse(success: true);
      fake.onGetAccessToken = (_) => GetAccessTokenResponse(
            token: 't',
            expiresInSeconds: Int64(60),
          );
      await adapter.authenticate(creds);

      fake.onInvalidate = (_) => InvalidateResponse();
      await adapter.invalidate();

      expect(fake.lastInvalidate?.clientId, 'atena-cli');

      // After invalidate, refresh falls back to defaultClientId.
      fake.onGetAccessToken = (req) => GetAccessTokenResponse(
            token: req.clientId,
            expiresInSeconds: Int64(10),
          );
      final t = await adapter.refreshToken();
      expect(t.accessToken, 'atena-default');
    });

    test('invalidate() wraps GrpcError as AuthenticationException', () async {
      fake.onInvalidate = (_) =>
          throw GrpcError.permissionDenied('nope');

      await expectLater(
        adapter.invalidate(),
        throwsA(
          isA<AuthenticationException>()
              .having((e) => e.vendorCode, "vendorCode", 'PERMISSION_DENIED'),
        ),
      );
    });

    test(
      'C10 regression: adapter surfaces StateError after channel shutdown '
      'instead of using a cached closed stub',
      () async {
        await harness.channelManager.shutdown();
        expect(
          () => adapter.isAuthenticated,
          throwsA(isA<StateError>()),
        );
      },
    );
  });
}
