/// Controllable fake implementations of every [Service] exposed by the
/// hacienda-sidecar proto. Each fake stores the last request it saw (for
/// assertion) and can be programmed to return a canned response or throw a
/// [GrpcError] so we can exercise the adapters' error-translation branches.
///
/// The fakes intentionally ignore the [ServiceCall] parameter — we only care
/// about request->response shape mapping from the client's perspective.
library;

import 'dart:async';

import 'package:grpc/grpc.dart';

// Use the adapters package's generated stubs so fakes and adapters share the
// exact same Message/Service classes (no duplicate-type ambiguity).
import 'package:aduanext_adapters/src/generated/hacienda.pbgrpc.dart';

/// Fake HaciendaAuthServiceBase with configurable handlers per RPC.
class FakeAuthService extends HaciendaAuthServiceBase {
  /// Programmable handler for `authenticate`. Defaults to success.
  FutureOr<AuthenticateResponse> Function(AuthenticateRequest request)?
      onAuthenticate;

  /// Programmable handler for `getAccessToken`. Defaults to an empty token.
  FutureOr<GetAccessTokenResponse> Function(GetAccessTokenRequest request)?
      onGetAccessToken;

  /// Programmable handler for `isAuthenticated`. Defaults to `false`.
  FutureOr<IsAuthenticatedResponse> Function(IsAuthenticatedRequest request)?
      onIsAuthenticated;

  /// Programmable handler for `invalidate`. Defaults to success.
  FutureOr<InvalidateResponse> Function(InvalidateRequest request)?
      onInvalidate;

  AuthenticateRequest? lastAuthenticate;
  GetAccessTokenRequest? lastGetAccessToken;
  IsAuthenticatedRequest? lastIsAuthenticated;
  InvalidateRequest? lastInvalidate;

  @override
  Future<AuthenticateResponse> authenticate(
    ServiceCall call,
    AuthenticateRequest request,
  ) async {
    lastAuthenticate = request;
    return await (onAuthenticate?.call(request) ??
        AuthenticateResponse(success: true, message: 'ok'));
  }

  @override
  Future<GetAccessTokenResponse> getAccessToken(
    ServiceCall call,
    GetAccessTokenRequest request,
  ) async {
    lastGetAccessToken = request;
    return await (onGetAccessToken?.call(request) ?? GetAccessTokenResponse());
  }

  @override
  Future<IsAuthenticatedResponse> isAuthenticated(
    ServiceCall call,
    IsAuthenticatedRequest request,
  ) async {
    lastIsAuthenticated = request;
    return await (onIsAuthenticated?.call(request) ??
        IsAuthenticatedResponse(authenticated: false));
  }

  @override
  Future<InvalidateResponse> invalidate(
    ServiceCall call,
    InvalidateRequest request,
  ) async {
    lastInvalidate = request;
    return await (onInvalidate?.call(request) ?? InvalidateResponse());
  }
}

/// Fake HaciendaSignerServiceBase with configurable handlers per RPC.
class FakeSignerService extends HaciendaSignerServiceBase {
  FutureOr<SignXmlResponse> Function(SignXmlRequest request)? onSignXml;
  FutureOr<SignAndEncodeResponse> Function(SignAndEncodeRequest request)?
      onSignAndEncode;
  FutureOr<VerifySignatureResponse> Function(VerifySignatureRequest request)?
      onVerifySignature;

  SignXmlRequest? lastSignXml;
  SignAndEncodeRequest? lastSignAndEncode;
  VerifySignatureRequest? lastVerify;

  @override
  Future<SignXmlResponse> signXml(
    ServiceCall call,
    SignXmlRequest request,
  ) async {
    lastSignXml = request;
    return await (onSignXml?.call(request) ?? SignXmlResponse());
  }

  @override
  Future<SignAndEncodeResponse> signAndEncode(
    ServiceCall call,
    SignAndEncodeRequest request,
  ) async {
    lastSignAndEncode = request;
    return await (onSignAndEncode?.call(request) ?? SignAndEncodeResponse());
  }

  @override
  Future<VerifySignatureResponse> verifySignature(
    ServiceCall call,
    VerifySignatureRequest request,
  ) async {
    lastVerify = request;
    return await (onVerifySignature?.call(request) ??
        VerifySignatureResponse(valid: true));
  }
}

/// Fake HaciendaApiServiceBase with configurable handlers per RPC.
class FakeApiService extends HaciendaApiServiceBase {
  FutureOr<GetDeclarationResponse> Function(GetDeclarationRequest request)?
      onGetDeclaration;
  FutureOr<ApiResponse> Function(ValidateDeclarationRequest request)?
      onValidateDeclaration;
  FutureOr<ApiResponse> Function(LiquidateDeclarationRequest request)?
      onLiquidateDeclaration;
  FutureOr<ApiResponse> Function(ValidateRectificationRequest request)?
      onValidateRectification;
  FutureOr<ApiResponse> Function(RectifyDeclarationRequest request)?
      onRectifyDeclaration;
  FutureOr<ApiResponse> Function(UploadDocumentRequest request)?
      onUploadDocument;
  FutureOr<RimmSearchResponse> Function(RimmSearchRequest request)?
      onRimmSearch;

  GetDeclarationRequest? lastGetDeclaration;
  ValidateDeclarationRequest? lastValidateDeclaration;
  LiquidateDeclarationRequest? lastLiquidateDeclaration;
  ValidateRectificationRequest? lastValidateRectification;
  RectifyDeclarationRequest? lastRectifyDeclaration;
  UploadDocumentRequest? lastUploadDocument;
  RimmSearchRequest? lastRimmSearch;

  @override
  Future<GetDeclarationResponse> getDeclaration(
    ServiceCall call,
    GetDeclarationRequest request,
  ) async {
    lastGetDeclaration = request;
    return await (onGetDeclaration?.call(request) ?? GetDeclarationResponse());
  }

  @override
  Future<ApiResponse> validateDeclaration(
    ServiceCall call,
    ValidateDeclarationRequest request,
  ) async {
    lastValidateDeclaration = request;
    return await (onValidateDeclaration?.call(request) ?? ApiResponse());
  }

  @override
  Future<ApiResponse> liquidateDeclaration(
    ServiceCall call,
    LiquidateDeclarationRequest request,
  ) async {
    lastLiquidateDeclaration = request;
    return await (onLiquidateDeclaration?.call(request) ?? ApiResponse());
  }

  @override
  Future<ApiResponse> validateRectification(
    ServiceCall call,
    ValidateRectificationRequest request,
  ) async {
    lastValidateRectification = request;
    return await (onValidateRectification?.call(request) ?? ApiResponse());
  }

  @override
  Future<ApiResponse> rectifyDeclaration(
    ServiceCall call,
    RectifyDeclarationRequest request,
  ) async {
    lastRectifyDeclaration = request;
    return await (onRectifyDeclaration?.call(request) ?? ApiResponse());
  }

  @override
  Future<ApiResponse> uploadDocument(
    ServiceCall call,
    UploadDocumentRequest request,
  ) async {
    lastUploadDocument = request;
    return await (onUploadDocument?.call(request) ?? ApiResponse());
  }

  @override
  Future<RimmSearchResponse> rimmSearch(
    ServiceCall call,
    RimmSearchRequest request,
  ) async {
    lastRimmSearch = request;
    return await (onRimmSearch?.call(request) ?? RimmSearchResponse());
  }
}
