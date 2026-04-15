/// Runtime configuration for [apps/server], parsed from environment
/// variables.
///
/// We deliberately avoid a framework-specific config system (e.g. Serverpod's
/// yaml) until the need arises — environment variables already drive the
/// helm-chart deployment, docker-compose, and CI, so aligning the local
/// binary with that contract keeps parity across environments.
library;

import 'dart:io';

/// Configuration for the AduaNext primary HTTP server.
class ServerConfig {
  /// Public bind address. Defaults to `0.0.0.0` so the server is reachable
  /// from outside localhost in a container, but individual environments
  /// should override with `ADUANEXT_HTTP_HOST=127.0.0.1` when exposing only
  /// to the loopback interface.
  final String httpHost;

  /// Public port for the AduaNext HTTP API.
  final int httpPort;

  /// Host for the `hacienda-sidecar` gRPC server. In docker-compose this is
  /// the service name; in local dev it's `localhost`.
  final String sidecarHost;

  /// Port for the hacienda-sidecar gRPC server. The sidecar's default.
  final int sidecarPort;

  /// Optional default OIDC client ID sent with auth RPCs that don't specify
  /// one on the credentials object. If null, the sidecar's own default is
  /// used.
  final String? defaultClientId;

  /// Path to the PKCS#12 (.p12) certificate file used for XAdES signing.
  /// Must be present and readable for signing operations to succeed.
  final String? p12CertPath;

  /// PIN for the PKCS#12 certificate.
  final String? p12Pin;

  /// Postgres connection URL for the audit log (e.g.
  /// `postgres://user:pass@host:5432/db`). Required in production; optional
  /// in development to allow running the server with the in-memory audit
  /// adapter for smoke tests.
  final String? postgresUrl;

  /// Full URL of the Keycloak JWKS endpoint, e.g.
  /// `https://keycloak.aduanext.cr/realms/aduanext/protocol/openid-connect/certs`.
  /// Required for protected routes — when null, every protected route
  /// returns 503 (fail-closed).
  final String? keycloakJwksUri;

  /// Expected `iss` claim on the JWT (must match Keycloak's realm URL).
  final String? keycloakIssuer;

  /// Expected `aud` claim on the JWT — the Keycloak client id used by
  /// this server (typically `aduanext-server`).
  final String? keycloakAudience;

  /// Absolute path to the `aduanext-pkcs11-helper` binary produced by
  /// VRTV-69. When set, AppContainer wires a [Pkcs11SigningPort] so
  /// the SubmitDeclaration handler can accept
  /// [HardwareTokenCredentials]. When null, submissions with
  /// hardware credentials fail-closed (no silent software fallback).
  final String? pkcs11HelperPath;

  const ServerConfig({
    required this.httpHost,
    required this.httpPort,
    required this.sidecarHost,
    required this.sidecarPort,
    this.defaultClientId,
    this.p12CertPath,
    this.p12Pin,
    this.postgresUrl,
    this.keycloakJwksUri,
    this.keycloakIssuer,
    this.keycloakAudience,
    this.pkcs11HelperPath,
  });

  /// Reads configuration from [Platform.environment] (or [source] for tests).
  factory ServerConfig.fromEnv([Map<String, String>? source]) {
    final env = source ?? Platform.environment;
    return ServerConfig(
      httpHost: env['ADUANEXT_HTTP_HOST'] ?? '0.0.0.0',
      httpPort: int.tryParse(env['ADUANEXT_HTTP_PORT'] ?? '') ?? 8180,
      sidecarHost: env['HACIENDA_SIDECAR_HOST'] ?? 'localhost',
      sidecarPort:
          int.tryParse(env['HACIENDA_SIDECAR_PORT'] ?? '') ?? 50051,
      defaultClientId: env['HACIENDA_DEFAULT_CLIENT_ID'],
      p12CertPath: env['HACIENDA_P12_PATH'],
      p12Pin: env['HACIENDA_P12_PIN'],
      postgresUrl: env['ADUANEXT_POSTGRES_URL'],
      keycloakJwksUri: env['KEYCLOAK_JWKS_URI'],
      keycloakIssuer: env['KEYCLOAK_ISSUER'],
      keycloakAudience: env['KEYCLOAK_AUDIENCE'],
      pkcs11HelperPath: env['PKCS11_HELPER_PATH'],
    );
  }
}
