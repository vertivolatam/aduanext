/// Adapter: Hacienda Signing — Implements [SigningPort] via gRPC sidecar.
///
/// Uses [HaciendaSignerClient] to sign XML documents with XAdES-EPES
/// using PKCS#12 (.p12) certificates from BCCR (Banco Central de Costa Rica).
///
/// The sidecar handles the actual cryptographic operations (Java-based
/// XAdES library). This adapter just marshals data to/from gRPC.
///
/// Architecture: Secondary Adapter (Driven side, Explicit Architecture).
library;

import 'package:aduanext_domain/domain.dart';
import 'package:grpc/grpc.dart';

import '../generated/hacienda.pbgrpc.dart';
import '../grpc/grpc_channel_manager.dart';

/// Domain exception for signing failures.
class SigningException implements Exception {
  final String message;
  final String? grpcCode;

  const SigningException(this.message, {this.grpcCode});

  @override
  String toString() => 'SigningException: $message'
      '${grpcCode != null ? ' (gRPC: $grpcCode)' : ''}';
}

/// Implements [SigningPort] by delegating to the hacienda-sidecar
/// [HaciendaSignerClient] gRPC service.
///
/// The PKCS#12 certificate bytes and PIN are provided at construction time
/// and reused for every signing operation.
class HaciendaSigningAdapter implements SigningPort {
  /// Default per-RPC deadline for signing operations. XAdES signing is
  /// CPU-bound in the sidecar but should comfortably complete well under
  /// this budget; the timeout is here to prevent pathological hangs when
  /// the sidecar is unresponsive.
  static const Duration defaultSigningTimeout = Duration(seconds: 15);

  final GrpcChannelManager _channelManager;
  final List<int> _p12Bytes;
  final String _p12Pin;
  final Duration _signingTimeout;

  /// Creates a signing adapter with the given certificate.
  ///
  /// [channelManager] manages the gRPC channel lifecycle.
  /// [p12Bytes] is the raw PKCS#12 certificate file content. A defensive
  /// unmodifiable copy is taken so the adapter's key material cannot be
  /// mutated from outside after construction.
  /// [p12Pin] is the PIN/password for the certificate.
  /// [signingTimeout] is the deadline passed to every gRPC call. Defaults to
  /// [defaultSigningTimeout]. Tune down for latency-sensitive callers or up
  /// when signing large batched payloads.
  HaciendaSigningAdapter({
    required GrpcChannelManager channelManager,
    required List<int> p12Bytes,
    required String p12Pin,
    Duration signingTimeout = defaultSigningTimeout,
  })  : _channelManager = channelManager,
        _p12Bytes = List<int>.unmodifiable(p12Bytes),
        _p12Pin = p12Pin,
        _signingTimeout = signingTimeout;

  /// Returns fresh [CallOptions] with the configured deadline.
  ///
  /// A new instance is returned per-call so the deadline is applied from the
  /// moment the RPC is issued rather than shared across calls.
  CallOptions _callOptions() => CallOptions(timeout: _signingTimeout);

  /// Returns a fresh gRPC stub backed by the current channel.
  ///
  /// Not cached — see [AtenaCustomsGatewayAdapter] for rationale: the
  /// channel lifecycle is managed externally and caching a stub risks
  /// leaking a closed channel reference across shutdown/terminate.
  HaciendaSignerClient get _signerClient =>
      HaciendaSignerClient(_channelManager.channel);

  @override
  Future<SigningResult> sign(String content) async {
    try {
      final response = await _signerClient.signXml(
        SignXmlRequest(
          xml: content,
          p12Buffer: _p12Bytes,
          p12Pin: _p12Pin,
        ),
        options: _callOptions(),
      );

      if (response.hasError() && response.error.isNotEmpty) {
        return SigningResult(
          success: false,
          errorMessage: response.error,
        );
      }

      return SigningResult(
        success: true,
        signedContent: response.signedXml,
      );
    } on GrpcError catch (e) {
      throw SigningException(
        e.message ?? 'gRPC error during XML signing',
        grpcCode: e.codeName,
      );
    }
  }

  @override
  Future<SigningResult> signAndEncode(String content) async {
    try {
      final response = await _signerClient.signAndEncode(
        SignAndEncodeRequest(
          xml: content,
          p12Buffer: _p12Bytes,
          p12Pin: _p12Pin,
        ),
        options: _callOptions(),
      );

      if (response.hasError() && response.error.isNotEmpty) {
        return SigningResult(
          success: false,
          errorMessage: response.error,
        );
      }

      return SigningResult(
        success: true,
        signedContent: response.base64SignedXml,
      );
    } on GrpcError catch (e) {
      throw SigningException(
        e.message ?? 'gRPC error during XML sign-and-encode',
        grpcCode: e.codeName,
      );
    }
  }

  @override
  Future<bool> verifySignature(String signedContent) async {
    try {
      final response = await _signerClient.verifySignature(
        VerifySignatureRequest(signedXml: signedContent),
        options: _callOptions(),
      );

      if (response.hasError() && response.error.isNotEmpty) {
        throw SigningException(
          'Signature verification failed: ${response.error}',
        );
      }

      return response.valid;
    } on GrpcError catch (e) {
      throw SigningException(
        e.message ?? 'gRPC error during signature verification',
        grpcCode: e.codeName,
      );
    }
  }
}
