// This is a generated file - do not edit.
//
// Generated from hacienda.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'hacienda.pb.dart' as $0;

export 'hacienda.pb.dart';

@$pb.GrpcServiceName('aduanext.hacienda.HaciendaAuth')
class HaciendaAuthClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  HaciendaAuthClient(super.channel, {super.options, super.interceptors});

  /// Authenticate with Hacienda IDP using ROPC credentials
  $grpc.ResponseFuture<$0.AuthenticateResponse> authenticate(
    $0.AuthenticateRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$authenticate, request, options: options);
  }

  /// Get cached access token (auto-refreshes 30s before expiry)
  $grpc.ResponseFuture<$0.GetAccessTokenResponse> getAccessToken(
    $0.GetAccessTokenRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getAccessToken, request, options: options);
  }

  /// Check if a valid session exists
  $grpc.ResponseFuture<$0.IsAuthenticatedResponse> isAuthenticated(
    $0.IsAuthenticatedRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$isAuthenticated, request, options: options);
  }

  /// Invalidate current session
  $grpc.ResponseFuture<$0.InvalidateResponse> invalidate(
    $0.InvalidateRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$invalidate, request, options: options);
  }

  // method descriptors

  static final _$authenticate =
      $grpc.ClientMethod<$0.AuthenticateRequest, $0.AuthenticateResponse>(
          '/aduanext.hacienda.HaciendaAuth/Authenticate',
          ($0.AuthenticateRequest value) => value.writeToBuffer(),
          $0.AuthenticateResponse.fromBuffer);
  static final _$getAccessToken =
      $grpc.ClientMethod<$0.GetAccessTokenRequest, $0.GetAccessTokenResponse>(
          '/aduanext.hacienda.HaciendaAuth/GetAccessToken',
          ($0.GetAccessTokenRequest value) => value.writeToBuffer(),
          $0.GetAccessTokenResponse.fromBuffer);
  static final _$isAuthenticated =
      $grpc.ClientMethod<$0.IsAuthenticatedRequest, $0.IsAuthenticatedResponse>(
          '/aduanext.hacienda.HaciendaAuth/IsAuthenticated',
          ($0.IsAuthenticatedRequest value) => value.writeToBuffer(),
          $0.IsAuthenticatedResponse.fromBuffer);
  static final _$invalidate =
      $grpc.ClientMethod<$0.InvalidateRequest, $0.InvalidateResponse>(
          '/aduanext.hacienda.HaciendaAuth/Invalidate',
          ($0.InvalidateRequest value) => value.writeToBuffer(),
          $0.InvalidateResponse.fromBuffer);
}

@$pb.GrpcServiceName('aduanext.hacienda.HaciendaAuth')
abstract class HaciendaAuthServiceBase extends $grpc.Service {
  $core.String get $name => 'aduanext.hacienda.HaciendaAuth';

  HaciendaAuthServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.AuthenticateRequest, $0.AuthenticateResponse>(
            'Authenticate',
            authenticate_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.AuthenticateRequest.fromBuffer(value),
            ($0.AuthenticateResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetAccessTokenRequest,
            $0.GetAccessTokenResponse>(
        'GetAccessToken',
        getAccessToken_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetAccessTokenRequest.fromBuffer(value),
        ($0.GetAccessTokenResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.IsAuthenticatedRequest,
            $0.IsAuthenticatedResponse>(
        'IsAuthenticated',
        isAuthenticated_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.IsAuthenticatedRequest.fromBuffer(value),
        ($0.IsAuthenticatedResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.InvalidateRequest, $0.InvalidateResponse>(
        'Invalidate',
        invalidate_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.InvalidateRequest.fromBuffer(value),
        ($0.InvalidateResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.AuthenticateResponse> authenticate_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.AuthenticateRequest> $request) async {
    return authenticate($call, await $request);
  }

  $async.Future<$0.AuthenticateResponse> authenticate(
      $grpc.ServiceCall call, $0.AuthenticateRequest request);

  $async.Future<$0.GetAccessTokenResponse> getAccessToken_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetAccessTokenRequest> $request) async {
    return getAccessToken($call, await $request);
  }

  $async.Future<$0.GetAccessTokenResponse> getAccessToken(
      $grpc.ServiceCall call, $0.GetAccessTokenRequest request);

  $async.Future<$0.IsAuthenticatedResponse> isAuthenticated_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.IsAuthenticatedRequest> $request) async {
    return isAuthenticated($call, await $request);
  }

  $async.Future<$0.IsAuthenticatedResponse> isAuthenticated(
      $grpc.ServiceCall call, $0.IsAuthenticatedRequest request);

  $async.Future<$0.InvalidateResponse> invalidate_Pre($grpc.ServiceCall $call,
      $async.Future<$0.InvalidateRequest> $request) async {
    return invalidate($call, await $request);
  }

  $async.Future<$0.InvalidateResponse> invalidate(
      $grpc.ServiceCall call, $0.InvalidateRequest request);
}

@$pb.GrpcServiceName('aduanext.hacienda.HaciendaSigner')
class HaciendaSignerClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  HaciendaSignerClient(super.channel, {super.options, super.interceptors});

  /// Sign XML with XAdES-EPES envelope signature
  $grpc.ResponseFuture<$0.SignXmlResponse> signXml(
    $0.SignXmlRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$signXml, request, options: options);
  }

  /// Sign XML and return as base64-encoded string (for ATENA submission)
  $grpc.ResponseFuture<$0.SignAndEncodeResponse> signAndEncode(
    $0.SignAndEncodeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$signAndEncode, request, options: options);
  }

  /// Verify a signed XML document
  $grpc.ResponseFuture<$0.VerifySignatureResponse> verifySignature(
    $0.VerifySignatureRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$verifySignature, request, options: options);
  }

  // method descriptors

  static final _$signXml =
      $grpc.ClientMethod<$0.SignXmlRequest, $0.SignXmlResponse>(
          '/aduanext.hacienda.HaciendaSigner/SignXml',
          ($0.SignXmlRequest value) => value.writeToBuffer(),
          $0.SignXmlResponse.fromBuffer);
  static final _$signAndEncode =
      $grpc.ClientMethod<$0.SignAndEncodeRequest, $0.SignAndEncodeResponse>(
          '/aduanext.hacienda.HaciendaSigner/SignAndEncode',
          ($0.SignAndEncodeRequest value) => value.writeToBuffer(),
          $0.SignAndEncodeResponse.fromBuffer);
  static final _$verifySignature =
      $grpc.ClientMethod<$0.VerifySignatureRequest, $0.VerifySignatureResponse>(
          '/aduanext.hacienda.HaciendaSigner/VerifySignature',
          ($0.VerifySignatureRequest value) => value.writeToBuffer(),
          $0.VerifySignatureResponse.fromBuffer);
}

@$pb.GrpcServiceName('aduanext.hacienda.HaciendaSigner')
abstract class HaciendaSignerServiceBase extends $grpc.Service {
  $core.String get $name => 'aduanext.hacienda.HaciendaSigner';

  HaciendaSignerServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.SignXmlRequest, $0.SignXmlResponse>(
        'SignXml',
        signXml_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SignXmlRequest.fromBuffer(value),
        ($0.SignXmlResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.SignAndEncodeRequest, $0.SignAndEncodeResponse>(
            'SignAndEncode',
            signAndEncode_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.SignAndEncodeRequest.fromBuffer(value),
            ($0.SignAndEncodeResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.VerifySignatureRequest,
            $0.VerifySignatureResponse>(
        'VerifySignature',
        verifySignature_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.VerifySignatureRequest.fromBuffer(value),
        ($0.VerifySignatureResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.SignXmlResponse> signXml_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SignXmlRequest> $request) async {
    return signXml($call, await $request);
  }

  $async.Future<$0.SignXmlResponse> signXml(
      $grpc.ServiceCall call, $0.SignXmlRequest request);

  $async.Future<$0.SignAndEncodeResponse> signAndEncode_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SignAndEncodeRequest> $request) async {
    return signAndEncode($call, await $request);
  }

  $async.Future<$0.SignAndEncodeResponse> signAndEncode(
      $grpc.ServiceCall call, $0.SignAndEncodeRequest request);

  $async.Future<$0.VerifySignatureResponse> verifySignature_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.VerifySignatureRequest> $request) async {
    return verifySignature($call, await $request);
  }

  $async.Future<$0.VerifySignatureResponse> verifySignature(
      $grpc.ServiceCall call, $0.VerifySignatureRequest request);
}

@$pb.GrpcServiceName('aduanext.hacienda.HaciendaApi')
class HaciendaApiClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  HaciendaApiClient(super.channel, {super.options, super.interceptors});

  /// DUA API #1: Get declaration by registration key
  $grpc.ResponseFuture<$0.GetDeclarationResponse> getDeclaration(
    $0.GetDeclarationRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getDeclaration, request, options: options);
  }

  /// DUA API #2: Validate declaration for liquidation
  $grpc.ResponseFuture<$0.ApiResponse> validateDeclaration(
    $0.ValidateDeclarationRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$validateDeclaration, request, options: options);
  }

  /// DUA API #3: Liquidate (assess) declaration
  $grpc.ResponseFuture<$0.ApiResponse> liquidateDeclaration(
    $0.LiquidateDeclarationRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$liquidateDeclaration, request, options: options);
  }

  /// DUA API #4: Validate DUA for rectification
  $grpc.ResponseFuture<$0.ApiResponse> validateRectification(
    $0.ValidateRectificationRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$validateRectification, request, options: options);
  }

  /// DUA API #5: Rectify declaration
  $grpc.ResponseFuture<$0.ApiResponse> rectifyDeclaration(
    $0.RectifyDeclarationRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$rectifyDeclaration, request, options: options);
  }

  /// DUA API #6: Upload attached document
  $grpc.ResponseFuture<$0.ApiResponse> uploadDocument(
    $0.UploadDocumentRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$uploadDocument, request, options: options);
  }

  /// RIMM: Generic search across any reference table
  $grpc.ResponseFuture<$0.RimmSearchResponse> rimmSearch(
    $0.RimmSearchRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$rimmSearch, request, options: options);
  }

  // method descriptors

  static final _$getDeclaration =
      $grpc.ClientMethod<$0.GetDeclarationRequest, $0.GetDeclarationResponse>(
          '/aduanext.hacienda.HaciendaApi/GetDeclaration',
          ($0.GetDeclarationRequest value) => value.writeToBuffer(),
          $0.GetDeclarationResponse.fromBuffer);
  static final _$validateDeclaration =
      $grpc.ClientMethod<$0.ValidateDeclarationRequest, $0.ApiResponse>(
          '/aduanext.hacienda.HaciendaApi/ValidateDeclaration',
          ($0.ValidateDeclarationRequest value) => value.writeToBuffer(),
          $0.ApiResponse.fromBuffer);
  static final _$liquidateDeclaration =
      $grpc.ClientMethod<$0.LiquidateDeclarationRequest, $0.ApiResponse>(
          '/aduanext.hacienda.HaciendaApi/LiquidateDeclaration',
          ($0.LiquidateDeclarationRequest value) => value.writeToBuffer(),
          $0.ApiResponse.fromBuffer);
  static final _$validateRectification =
      $grpc.ClientMethod<$0.ValidateRectificationRequest, $0.ApiResponse>(
          '/aduanext.hacienda.HaciendaApi/ValidateRectification',
          ($0.ValidateRectificationRequest value) => value.writeToBuffer(),
          $0.ApiResponse.fromBuffer);
  static final _$rectifyDeclaration =
      $grpc.ClientMethod<$0.RectifyDeclarationRequest, $0.ApiResponse>(
          '/aduanext.hacienda.HaciendaApi/RectifyDeclaration',
          ($0.RectifyDeclarationRequest value) => value.writeToBuffer(),
          $0.ApiResponse.fromBuffer);
  static final _$uploadDocument =
      $grpc.ClientMethod<$0.UploadDocumentRequest, $0.ApiResponse>(
          '/aduanext.hacienda.HaciendaApi/UploadDocument',
          ($0.UploadDocumentRequest value) => value.writeToBuffer(),
          $0.ApiResponse.fromBuffer);
  static final _$rimmSearch =
      $grpc.ClientMethod<$0.RimmSearchRequest, $0.RimmSearchResponse>(
          '/aduanext.hacienda.HaciendaApi/RimmSearch',
          ($0.RimmSearchRequest value) => value.writeToBuffer(),
          $0.RimmSearchResponse.fromBuffer);
}

@$pb.GrpcServiceName('aduanext.hacienda.HaciendaApi')
abstract class HaciendaApiServiceBase extends $grpc.Service {
  $core.String get $name => 'aduanext.hacienda.HaciendaApi';

  HaciendaApiServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.GetDeclarationRequest,
            $0.GetDeclarationResponse>(
        'GetDeclaration',
        getDeclaration_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetDeclarationRequest.fromBuffer(value),
        ($0.GetDeclarationResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ValidateDeclarationRequest, $0.ApiResponse>(
            'ValidateDeclaration',
            validateDeclaration_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ValidateDeclarationRequest.fromBuffer(value),
            ($0.ApiResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.LiquidateDeclarationRequest, $0.ApiResponse>(
            'LiquidateDeclaration',
            liquidateDeclaration_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.LiquidateDeclarationRequest.fromBuffer(value),
            ($0.ApiResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ValidateRectificationRequest, $0.ApiResponse>(
            'ValidateRectification',
            validateRectification_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ValidateRectificationRequest.fromBuffer(value),
            ($0.ApiResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.RectifyDeclarationRequest, $0.ApiResponse>(
            'RectifyDeclaration',
            rectifyDeclaration_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.RectifyDeclarationRequest.fromBuffer(value),
            ($0.ApiResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UploadDocumentRequest, $0.ApiResponse>(
        'UploadDocument',
        uploadDocument_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.UploadDocumentRequest.fromBuffer(value),
        ($0.ApiResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RimmSearchRequest, $0.RimmSearchResponse>(
        'RimmSearch',
        rimmSearch_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.RimmSearchRequest.fromBuffer(value),
        ($0.RimmSearchResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.GetDeclarationResponse> getDeclaration_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetDeclarationRequest> $request) async {
    return getDeclaration($call, await $request);
  }

  $async.Future<$0.GetDeclarationResponse> getDeclaration(
      $grpc.ServiceCall call, $0.GetDeclarationRequest request);

  $async.Future<$0.ApiResponse> validateDeclaration_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ValidateDeclarationRequest> $request) async {
    return validateDeclaration($call, await $request);
  }

  $async.Future<$0.ApiResponse> validateDeclaration(
      $grpc.ServiceCall call, $0.ValidateDeclarationRequest request);

  $async.Future<$0.ApiResponse> liquidateDeclaration_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.LiquidateDeclarationRequest> $request) async {
    return liquidateDeclaration($call, await $request);
  }

  $async.Future<$0.ApiResponse> liquidateDeclaration(
      $grpc.ServiceCall call, $0.LiquidateDeclarationRequest request);

  $async.Future<$0.ApiResponse> validateRectification_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ValidateRectificationRequest> $request) async {
    return validateRectification($call, await $request);
  }

  $async.Future<$0.ApiResponse> validateRectification(
      $grpc.ServiceCall call, $0.ValidateRectificationRequest request);

  $async.Future<$0.ApiResponse> rectifyDeclaration_Pre($grpc.ServiceCall $call,
      $async.Future<$0.RectifyDeclarationRequest> $request) async {
    return rectifyDeclaration($call, await $request);
  }

  $async.Future<$0.ApiResponse> rectifyDeclaration(
      $grpc.ServiceCall call, $0.RectifyDeclarationRequest request);

  $async.Future<$0.ApiResponse> uploadDocument_Pre($grpc.ServiceCall $call,
      $async.Future<$0.UploadDocumentRequest> $request) async {
    return uploadDocument($call, await $request);
  }

  $async.Future<$0.ApiResponse> uploadDocument(
      $grpc.ServiceCall call, $0.UploadDocumentRequest request);

  $async.Future<$0.RimmSearchResponse> rimmSearch_Pre($grpc.ServiceCall $call,
      $async.Future<$0.RimmSearchRequest> $request) async {
    return rimmSearch($call, await $request);
  }

  $async.Future<$0.RimmSearchResponse> rimmSearch(
      $grpc.ServiceCall call, $0.RimmSearchRequest request);
}

@$pb.GrpcServiceName('aduanext.hacienda.HaciendaOrchestrator')
class HaciendaOrchestratorClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  HaciendaOrchestratorClient(super.channel,
      {super.options, super.interceptors});

  /// Full workflow: authenticate → validate → sign → submit → return result
  $grpc.ResponseFuture<$0.SubmitSignedDeclarationResponse>
      submitSignedDeclaration(
    $0.SubmitSignedDeclarationRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$submitSignedDeclaration, request,
        options: options);
  }

  // method descriptors

  static final _$submitSignedDeclaration = $grpc.ClientMethod<
          $0.SubmitSignedDeclarationRequest,
          $0.SubmitSignedDeclarationResponse>(
      '/aduanext.hacienda.HaciendaOrchestrator/SubmitSignedDeclaration',
      ($0.SubmitSignedDeclarationRequest value) => value.writeToBuffer(),
      $0.SubmitSignedDeclarationResponse.fromBuffer);
}

@$pb.GrpcServiceName('aduanext.hacienda.HaciendaOrchestrator')
abstract class HaciendaOrchestratorServiceBase extends $grpc.Service {
  $core.String get $name => 'aduanext.hacienda.HaciendaOrchestrator';

  HaciendaOrchestratorServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.SubmitSignedDeclarationRequest,
            $0.SubmitSignedDeclarationResponse>(
        'SubmitSignedDeclaration',
        submitSignedDeclaration_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SubmitSignedDeclarationRequest.fromBuffer(value),
        ($0.SubmitSignedDeclarationResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.SubmitSignedDeclarationResponse> submitSignedDeclaration_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SubmitSignedDeclarationRequest> $request) async {
    return submitSignedDeclaration($call, await $request);
  }

  $async.Future<$0.SubmitSignedDeclarationResponse> submitSignedDeclaration(
      $grpc.ServiceCall call, $0.SubmitSignedDeclarationRequest request);
}
