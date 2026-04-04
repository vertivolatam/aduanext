// This is a generated file - do not edit.
//
// Generated from hacienda.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class AuthenticateRequest extends $pb.GeneratedMessage {
  factory AuthenticateRequest({
    $core.String? idType,
    $core.String? idNumber,
    $core.String? password,
    $core.String? clientId,
    $core.String? environment,
  }) {
    final result = create();
    if (idType != null) result.idType = idType;
    if (idNumber != null) result.idNumber = idNumber;
    if (password != null) result.password = password;
    if (clientId != null) result.clientId = clientId;
    if (environment != null) result.environment = environment;
    return result;
  }

  AuthenticateRequest._();

  factory AuthenticateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AuthenticateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AuthenticateRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'aduanext.hacienda'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'idType')
    ..aOS(2, _omitFieldNames ? '' : 'idNumber')
    ..aOS(3, _omitFieldNames ? '' : 'password')
    ..aOS(4, _omitFieldNames ? '' : 'clientId')
    ..aOS(5, _omitFieldNames ? '' : 'environment')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AuthenticateRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AuthenticateRequest copyWith(void Function(AuthenticateRequest) updates) =>
      super.copyWith((message) => updates(message as AuthenticateRequest))
          as AuthenticateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AuthenticateRequest create() => AuthenticateRequest._();
  @$core.override
  AuthenticateRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AuthenticateRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AuthenticateRequest>(create);
  static AuthenticateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get idType => $_getSZ(0);
  @$pb.TagNumber(1)
  set idType($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIdType() => $_has(0);
  @$pb.TagNumber(1)
  void clearIdType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get idNumber => $_getSZ(1);
  @$pb.TagNumber(2)
  set idNumber($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIdNumber() => $_has(1);
  @$pb.TagNumber(2)
  void clearIdNumber() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get password => $_getSZ(2);
  @$pb.TagNumber(3)
  set password($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPassword() => $_has(2);
  @$pb.TagNumber(3)
  void clearPassword() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get clientId => $_getSZ(3);
  @$pb.TagNumber(4)
  set clientId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasClientId() => $_has(3);
  @$pb.TagNumber(4)
  void clearClientId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get environment => $_getSZ(4);
  @$pb.TagNumber(5)
  set environment($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasEnvironment() => $_has(4);
  @$pb.TagNumber(5)
  void clearEnvironment() => $_clearField(5);
}

class AuthenticateResponse extends $pb.GeneratedMessage {
  factory AuthenticateResponse({
    $core.bool? success,
    $core.String? message,
    $core.String? errorCode,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (errorCode != null) result.errorCode = errorCode;
    return result;
  }

  AuthenticateResponse._();

  factory AuthenticateResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AuthenticateResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AuthenticateResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'aduanext.hacienda'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOS(3, _omitFieldNames ? '' : 'errorCode')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AuthenticateResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AuthenticateResponse copyWith(void Function(AuthenticateResponse) updates) =>
      super.copyWith((message) => updates(message as AuthenticateResponse))
          as AuthenticateResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AuthenticateResponse create() => AuthenticateResponse._();
  @$core.override
  AuthenticateResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AuthenticateResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AuthenticateResponse>(create);
  static AuthenticateResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get errorCode => $_getSZ(2);
  @$pb.TagNumber(3)
  set errorCode($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasErrorCode() => $_has(2);
  @$pb.TagNumber(3)
  void clearErrorCode() => $_clearField(3);
}

class GetAccessTokenRequest extends $pb.GeneratedMessage {
  factory GetAccessTokenRequest({
    $core.String? clientId,
  }) {
    final result = create();
    if (clientId != null) result.clientId = clientId;
    return result;
  }

  GetAccessTokenRequest._();

  factory GetAccessTokenRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetAccessTokenRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetAccessTokenRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'aduanext.hacienda'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'clientId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAccessTokenRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAccessTokenRequest copyWith(
          void Function(GetAccessTokenRequest) updates) =>
      super.copyWith((message) => updates(message as GetAccessTokenRequest))
          as GetAccessTokenRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetAccessTokenRequest create() => GetAccessTokenRequest._();
  @$core.override
  GetAccessTokenRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetAccessTokenRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetAccessTokenRequest>(create);
  static GetAccessTokenRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get clientId => $_getSZ(0);
  @$pb.TagNumber(1)
  set clientId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasClientId() => $_has(0);
  @$pb.TagNumber(1)
  void clearClientId() => $_clearField(1);
}

class GetAccessTokenResponse extends $pb.GeneratedMessage {
  factory GetAccessTokenResponse({
    $core.String? token,
    $fixnum.Int64? expiresInSeconds,
    $core.String? tokenType,
    $core.String? scope,
  }) {
    final result = create();
    if (token != null) result.token = token;
    if (expiresInSeconds != null) result.expiresInSeconds = expiresInSeconds;
    if (tokenType != null) result.tokenType = tokenType;
    if (scope != null) result.scope = scope;
    return result;
  }

  GetAccessTokenResponse._();

  factory GetAccessTokenResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetAccessTokenResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetAccessTokenResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'aduanext.hacienda'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'token')
    ..aInt64(2, _omitFieldNames ? '' : 'expiresInSeconds')
    ..aOS(3, _omitFieldNames ? '' : 'tokenType')
    ..aOS(4, _omitFieldNames ? '' : 'scope')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAccessTokenResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAccessTokenResponse copyWith(
          void Function(GetAccessTokenResponse) updates) =>
      super.copyWith((message) => updates(message as GetAccessTokenResponse))
          as GetAccessTokenResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetAccessTokenResponse create() => GetAccessTokenResponse._();
  @$core.override
  GetAccessTokenResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetAccessTokenResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetAccessTokenResponse>(create);
  static GetAccessTokenResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get token => $_getSZ(0);
  @$pb.TagNumber(1)
  set token($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearToken() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get expiresInSeconds => $_getI64(1);
  @$pb.TagNumber(2)
  set expiresInSeconds($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasExpiresInSeconds() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpiresInSeconds() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get tokenType => $_getSZ(2);
  @$pb.TagNumber(3)
  set tokenType($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTokenType() => $_has(2);
  @$pb.TagNumber(3)
  void clearTokenType() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get scope => $_getSZ(3);
  @$pb.TagNumber(4)
  set scope($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasScope() => $_has(3);
  @$pb.TagNumber(4)
  void clearScope() => $_clearField(4);
}

class IsAuthenticatedRequest extends $pb.GeneratedMessage {
  factory IsAuthenticatedRequest({
    $core.String? clientId,
  }) {
    final result = create();
    if (clientId != null) result.clientId = clientId;
    return result;
  }

  IsAuthenticatedRequest._();

  factory IsAuthenticatedRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IsAuthenticatedRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IsAuthenticatedRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'aduanext.hacienda'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'clientId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IsAuthenticatedRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IsAuthenticatedRequest copyWith(
          void Function(IsAuthenticatedRequest) updates) =>
      super.copyWith((message) => updates(message as IsAuthenticatedRequest))
          as IsAuthenticatedRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IsAuthenticatedRequest create() => IsAuthenticatedRequest._();
  @$core.override
  IsAuthenticatedRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static IsAuthenticatedRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<IsAuthenticatedRequest>(create);
  static IsAuthenticatedRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get clientId => $_getSZ(0);
  @$pb.TagNumber(1)
  set clientId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasClientId() => $_has(0);
  @$pb.TagNumber(1)
  void clearClientId() => $_clearField(1);
}

class IsAuthenticatedResponse extends $pb.GeneratedMessage {
  factory IsAuthenticatedResponse({
    $core.bool? authenticated,
  }) {
    final result = create();
    if (authenticated != null) result.authenticated = authenticated;
    return result;
  }

  IsAuthenticatedResponse._();

  factory IsAuthenticatedResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IsAuthenticatedResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IsAuthenticatedResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'aduanext.hacienda'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'authenticated')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IsAuthenticatedResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IsAuthenticatedResponse copyWith(
          void Function(IsAuthenticatedResponse) updates) =>
      super.copyWith((message) => updates(message as IsAuthenticatedResponse))
          as IsAuthenticatedResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IsAuthenticatedResponse create() => IsAuthenticatedResponse._();
  @$core.override
  IsAuthenticatedResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static IsAuthenticatedResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<IsAuthenticatedResponse>(create);
  static IsAuthenticatedResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get authenticated => $_getBF(0);
  @$pb.TagNumber(1)
  set authenticated($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAuthenticated() => $_has(0);
  @$pb.TagNumber(1)
  void clearAuthenticated() => $_clearField(1);
}

class InvalidateRequest extends $pb.GeneratedMessage {
  factory InvalidateRequest({
    $core.String? clientId,
  }) {
    final result = create();
    if (clientId != null) result.clientId = clientId;
    return result;
  }

  InvalidateRequest._();

  factory InvalidateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InvalidateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InvalidateRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'aduanext.hacienda'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'clientId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InvalidateRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InvalidateRequest copyWith(void Function(InvalidateRequest) updates) =>
      super.copyWith((message) => updates(message as InvalidateRequest))
          as InvalidateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InvalidateRequest create() => InvalidateRequest._();
  @$core.override
  InvalidateRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InvalidateRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InvalidateRequest>(create);
  static InvalidateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get clientId => $_getSZ(0);
  @$pb.TagNumber(1)
  set clientId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasClientId() => $_has(0);
  @$pb.TagNumber(1)
  void clearClientId() => $_clearField(1);
}

class InvalidateResponse extends $pb.GeneratedMessage {
  factory InvalidateResponse({
    $core.bool? success,
  }) {
    final result = create();
    if (success != null) result.success = success;
    return result;
  }

  InvalidateResponse._();

  factory InvalidateResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InvalidateResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InvalidateResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'aduanext.hacienda'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InvalidateResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InvalidateResponse copyWith(void Function(InvalidateResponse) updates) =>
      super.copyWith((message) => updates(message as InvalidateResponse))
          as InvalidateResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InvalidateResponse create() => InvalidateResponse._();
  @$core.override
  InvalidateResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InvalidateResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InvalidateResponse>(create);
  static InvalidateResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);
}

class SignXmlRequest extends $pb.GeneratedMessage {
  factory SignXmlRequest({
    $core.String? xml,
    $core.List<$core.int>? p12Buffer,
    $core.String? p12Pin,
  }) {
    final result = create();
    if (xml != null) result.xml = xml;
    if (p12Buffer != null) result.p12Buffer = p12Buffer;
    if (p12Pin != null) result.p12Pin = p12Pin;
    return result;
  }

  SignXmlRequest._();

  factory SignXmlRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SignXmlRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SignXmlRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'aduanext.hacienda'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'xml')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'p12Buffer', $pb.PbFieldType.OY)
    ..aOS(3, _omitFieldNames ? '' : 'p12Pin')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SignXmlRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SignXmlRequest copyWith(void Function(SignXmlRequest) updates) =>
      super.copyWith((message) => updates(message as SignXmlRequest))
          as SignXmlRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SignXmlRequest create() => SignXmlRequest._();
  @$core.override
  SignXmlRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SignXmlRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SignXmlRequest>(create);
  static SignXmlRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get xml => $_getSZ(0);
  @$pb.TagNumber(1)
  set xml($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasXml() => $_has(0);
  @$pb.TagNumber(1)
  void clearXml() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get p12Buffer => $_getN(1);
  @$pb.TagNumber(2)
  set p12Buffer($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasP12Buffer() => $_has(1);
  @$pb.TagNumber(2)
  void clearP12Buffer() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get p12Pin => $_getSZ(2);
  @$pb.TagNumber(3)
  set p12Pin($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasP12Pin() => $_has(2);
  @$pb.TagNumber(3)
  void clearP12Pin() => $_clearField(3);
}

class SignXmlResponse extends $pb.GeneratedMessage {
  factory SignXmlResponse({
    $core.String? signedXml,
    $core.String? error,
  }) {
    final result = create();
    if (signedXml != null) result.signedXml = signedXml;
    if (error != null) result.error = error;
    return result;
  }

  SignXmlResponse._();

  factory SignXmlResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SignXmlResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SignXmlResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'aduanext.hacienda'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'signedXml')
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SignXmlResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SignXmlResponse copyWith(void Function(SignXmlResponse) updates) =>
      super.copyWith((message) => updates(message as SignXmlResponse))
          as SignXmlResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SignXmlResponse create() => SignXmlResponse._();
  @$core.override
  SignXmlResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SignXmlResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SignXmlResponse>(create);
  static SignXmlResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get signedXml => $_getSZ(0);
  @$pb.TagNumber(1)
  set signedXml($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSignedXml() => $_has(0);
  @$pb.TagNumber(1)
  void clearSignedXml() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get error => $_getSZ(1);
  @$pb.TagNumber(2)
  set error($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
}

class SignAndEncodeRequest extends $pb.GeneratedMessage {
  factory SignAndEncodeRequest({
    $core.String? xml,
    $core.List<$core.int>? p12Buffer,
    $core.String? p12Pin,
  }) {
    final result = create();
    if (xml != null) result.xml = xml;
    if (p12Buffer != null) result.p12Buffer = p12Buffer;
    if (p12Pin != null) result.p12Pin = p12Pin;
    return result;
  }

  SignAndEncodeRequest._();

  factory SignAndEncodeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SignAndEncodeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SignAndEncodeRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'aduanext.hacienda'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'xml')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'p12Buffer', $pb.PbFieldType.OY)
    ..aOS(3, _omitFieldNames ? '' : 'p12Pin')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SignAndEncodeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SignAndEncodeRequest copyWith(void Function(SignAndEncodeRequest) updates) =>
      super.copyWith((message) => updates(message as SignAndEncodeRequest))
          as SignAndEncodeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SignAndEncodeRequest create() => SignAndEncodeRequest._();
  @$core.override
  SignAndEncodeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SignAndEncodeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SignAndEncodeRequest>(create);
  static SignAndEncodeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get xml => $_getSZ(0);
  @$pb.TagNumber(1)
  set xml($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasXml() => $_has(0);
  @$pb.TagNumber(1)
  void clearXml() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get p12Buffer => $_getN(1);
  @$pb.TagNumber(2)
  set p12Buffer($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasP12Buffer() => $_has(1);
  @$pb.TagNumber(2)
  void clearP12Buffer() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get p12Pin => $_getSZ(2);
  @$pb.TagNumber(3)
  set p12Pin($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasP12Pin() => $_has(2);
  @$pb.TagNumber(3)
  void clearP12Pin() => $_clearField(3);
}

class SignAndEncodeResponse extends $pb.GeneratedMessage {
  factory SignAndEncodeResponse({
    $core.String? base64SignedXml,
    $core.String? error,
  }) {
    final result = create();
    if (base64SignedXml != null) result.base64SignedXml = base64SignedXml;
    if (error != null) result.error = error;
    return result;
  }

  SignAndEncodeResponse._();

  factory SignAndEncodeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SignAndEncodeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SignAndEncodeResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'aduanext.hacienda'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'base64SignedXml')
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SignAndEncodeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SignAndEncodeResponse copyWith(
          void Function(SignAndEncodeResponse) updates) =>
      super.copyWith((message) => updates(message as SignAndEncodeResponse))
          as SignAndEncodeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SignAndEncodeResponse create() => SignAndEncodeResponse._();
  @$core.override
  SignAndEncodeResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SignAndEncodeResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SignAndEncodeResponse>(create);
  static SignAndEncodeResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get base64SignedXml => $_getSZ(0);
  @$pb.TagNumber(1)
  set base64SignedXml($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBase64SignedXml() => $_has(0);
  @$pb.TagNumber(1)
  void clearBase64SignedXml() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get error => $_getSZ(1);
  @$pb.TagNumber(2)
  set error($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
}

class VerifySignatureRequest extends $pb.GeneratedMessage {
  factory VerifySignatureRequest({
    $core.String? signedXml,
  }) {
    final result = create();
    if (signedXml != null) result.signedXml = signedXml;
    return result;
  }

  VerifySignatureRequest._();

  factory VerifySignatureRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory VerifySignatureRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VerifySignatureRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'aduanext.hacienda'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'signedXml')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VerifySignatureRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VerifySignatureRequest copyWith(
          void Function(VerifySignatureRequest) updates) =>
      super.copyWith((message) => updates(message as VerifySignatureRequest))
          as VerifySignatureRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static VerifySignatureRequest create() => VerifySignatureRequest._();
  @$core.override
  VerifySignatureRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static VerifySignatureRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<VerifySignatureRequest>(create);
  static VerifySignatureRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get signedXml => $_getSZ(0);
  @$pb.TagNumber(1)
  set signedXml($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSignedXml() => $_has(0);
  @$pb.TagNumber(1)
  void clearSignedXml() => $_clearField(1);
}

class VerifySignatureResponse extends $pb.GeneratedMessage {
  factory VerifySignatureResponse({
    $core.bool? valid,
    $core.String? signerCn,
    $core.String? error,
  }) {
    final result = create();
    if (valid != null) result.valid = valid;
    if (signerCn != null) result.signerCn = signerCn;
    if (error != null) result.error = error;
    return result;
  }

  VerifySignatureResponse._();

  factory VerifySignatureResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory VerifySignatureResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VerifySignatureResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'aduanext.hacienda'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'valid')
    ..aOS(2, _omitFieldNames ? '' : 'signerCn')
    ..aOS(3, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VerifySignatureResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VerifySignatureResponse copyWith(
          void Function(VerifySignatureResponse) updates) =>
      super.copyWith((message) => updates(message as VerifySignatureResponse))
          as VerifySignatureResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static VerifySignatureResponse create() => VerifySignatureResponse._();
  @$core.override
  VerifySignatureResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static VerifySignatureResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<VerifySignatureResponse>(create);
  static VerifySignatureResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get valid => $_getBF(0);
  @$pb.TagNumber(1)
  set valid($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValid() => $_has(0);
  @$pb.TagNumber(1)
  void clearValid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get signerCn => $_getSZ(1);
  @$pb.TagNumber(2)
  set signerCn($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSignerCn() => $_has(1);
  @$pb.TagNumber(2)
  void clearSignerCn() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get error => $_getSZ(2);
  @$pb.TagNumber(3)
  set error($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasError() => $_has(2);
  @$pb.TagNumber(3)
  void clearError() => $_clearField(3);
}

class GetDeclarationRequest extends $pb.GeneratedMessage {
  factory GetDeclarationRequest({
    $core.String? customsOfficeCode,
    $core.String? serial,
    $core.int? number,
    $core.int? year,
  }) {
    final result = create();
    if (customsOfficeCode != null) result.customsOfficeCode = customsOfficeCode;
    if (serial != null) result.serial = serial;
    if (number != null) result.number = number;
    if (year != null) result.year = year;
    return result;
  }

  GetDeclarationRequest._();

  factory GetDeclarationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetDeclarationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetDeclarationRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'aduanext.hacienda'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'customsOfficeCode')
    ..aOS(2, _omitFieldNames ? '' : 'serial')
    ..aI(3, _omitFieldNames ? '' : 'number')
    ..aI(4, _omitFieldNames ? '' : 'year')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetDeclarationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetDeclarationRequest copyWith(
          void Function(GetDeclarationRequest) updates) =>
      super.copyWith((message) => updates(message as GetDeclarationRequest))
          as GetDeclarationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetDeclarationRequest create() => GetDeclarationRequest._();
  @$core.override
  GetDeclarationRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetDeclarationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetDeclarationRequest>(create);
  static GetDeclarationRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get customsOfficeCode => $_getSZ(0);
  @$pb.TagNumber(1)
  set customsOfficeCode($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCustomsOfficeCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCustomsOfficeCode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get serial => $_getSZ(1);
  @$pb.TagNumber(2)
  set serial($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSerial() => $_has(1);
  @$pb.TagNumber(2)
  void clearSerial() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get number => $_getIZ(2);
  @$pb.TagNumber(3)
  set number($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNumber() => $_has(2);
  @$pb.TagNumber(3)
  void clearNumber() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get year => $_getIZ(3);
  @$pb.TagNumber(4)
  set year($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasYear() => $_has(3);
  @$pb.TagNumber(4)
  void clearYear() => $_clearField(4);
}

class GetDeclarationResponse extends $pb.GeneratedMessage {
  factory GetDeclarationResponse({
    $core.String? jsonPayload,
    $core.int? httpStatus,
    $core.String? error,
  }) {
    final result = create();
    if (jsonPayload != null) result.jsonPayload = jsonPayload;
    if (httpStatus != null) result.httpStatus = httpStatus;
    if (error != null) result.error = error;
    return result;
  }

  GetDeclarationResponse._();

  factory GetDeclarationResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetDeclarationResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetDeclarationResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'aduanext.hacienda'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'jsonPayload')
    ..aI(2, _omitFieldNames ? '' : 'httpStatus')
    ..aOS(3, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetDeclarationResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetDeclarationResponse copyWith(
          void Function(GetDeclarationResponse) updates) =>
      super.copyWith((message) => updates(message as GetDeclarationResponse))
          as GetDeclarationResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetDeclarationResponse create() => GetDeclarationResponse._();
  @$core.override
  GetDeclarationResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetDeclarationResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetDeclarationResponse>(create);
  static GetDeclarationResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get jsonPayload => $_getSZ(0);
  @$pb.TagNumber(1)
  set jsonPayload($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasJsonPayload() => $_has(0);
  @$pb.TagNumber(1)
  void clearJsonPayload() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get httpStatus => $_getIZ(1);
  @$pb.TagNumber(2)
  set httpStatus($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHttpStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearHttpStatus() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get error => $_getSZ(2);
  @$pb.TagNumber(3)
  set error($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasError() => $_has(2);
  @$pb.TagNumber(3)
  void clearError() => $_clearField(3);
}

class ValidateDeclarationRequest extends $pb.GeneratedMessage {
  factory ValidateDeclarationRequest({
    $core.String? jsonPayload,
  }) {
    final result = create();
    if (jsonPayload != null) result.jsonPayload = jsonPayload;
    return result;
  }

  ValidateDeclarationRequest._();

  factory ValidateDeclarationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ValidateDeclarationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ValidateDeclarationRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'aduanext.hacienda'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'jsonPayload')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ValidateDeclarationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ValidateDeclarationRequest copyWith(
          void Function(ValidateDeclarationRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ValidateDeclarationRequest))
          as ValidateDeclarationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ValidateDeclarationRequest create() => ValidateDeclarationRequest._();
  @$core.override
  ValidateDeclarationRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ValidateDeclarationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ValidateDeclarationRequest>(create);
  static ValidateDeclarationRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get jsonPayload => $_getSZ(0);
  @$pb.TagNumber(1)
  set jsonPayload($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasJsonPayload() => $_has(0);
  @$pb.TagNumber(1)
  void clearJsonPayload() => $_clearField(1);
}

class LiquidateDeclarationRequest extends $pb.GeneratedMessage {
  factory LiquidateDeclarationRequest({
    $core.String? jsonPayload,
  }) {
    final result = create();
    if (jsonPayload != null) result.jsonPayload = jsonPayload;
    return result;
  }

  LiquidateDeclarationRequest._();

  factory LiquidateDeclarationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LiquidateDeclarationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LiquidateDeclarationRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'aduanext.hacienda'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'jsonPayload')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiquidateDeclarationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiquidateDeclarationRequest copyWith(
          void Function(LiquidateDeclarationRequest) updates) =>
      super.copyWith(
              (message) => updates(message as LiquidateDeclarationRequest))
          as LiquidateDeclarationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LiquidateDeclarationRequest create() =>
      LiquidateDeclarationRequest._();
  @$core.override
  LiquidateDeclarationRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LiquidateDeclarationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LiquidateDeclarationRequest>(create);
  static LiquidateDeclarationRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get jsonPayload => $_getSZ(0);
  @$pb.TagNumber(1)
  set jsonPayload($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasJsonPayload() => $_has(0);
  @$pb.TagNumber(1)
  void clearJsonPayload() => $_clearField(1);
}

class ValidateRectificationRequest extends $pb.GeneratedMessage {
  factory ValidateRectificationRequest({
    $core.String? jsonPayload,
  }) {
    final result = create();
    if (jsonPayload != null) result.jsonPayload = jsonPayload;
    return result;
  }

  ValidateRectificationRequest._();

  factory ValidateRectificationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ValidateRectificationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ValidateRectificationRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'aduanext.hacienda'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'jsonPayload')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ValidateRectificationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ValidateRectificationRequest copyWith(
          void Function(ValidateRectificationRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ValidateRectificationRequest))
          as ValidateRectificationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ValidateRectificationRequest create() =>
      ValidateRectificationRequest._();
  @$core.override
  ValidateRectificationRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ValidateRectificationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ValidateRectificationRequest>(create);
  static ValidateRectificationRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get jsonPayload => $_getSZ(0);
  @$pb.TagNumber(1)
  set jsonPayload($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasJsonPayload() => $_has(0);
  @$pb.TagNumber(1)
  void clearJsonPayload() => $_clearField(1);
}

class RectifyDeclarationRequest extends $pb.GeneratedMessage {
  factory RectifyDeclarationRequest({
    $core.String? jsonPayload,
  }) {
    final result = create();
    if (jsonPayload != null) result.jsonPayload = jsonPayload;
    return result;
  }

  RectifyDeclarationRequest._();

  factory RectifyDeclarationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RectifyDeclarationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RectifyDeclarationRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'aduanext.hacienda'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'jsonPayload')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RectifyDeclarationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RectifyDeclarationRequest copyWith(
          void Function(RectifyDeclarationRequest) updates) =>
      super.copyWith((message) => updates(message as RectifyDeclarationRequest))
          as RectifyDeclarationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RectifyDeclarationRequest create() => RectifyDeclarationRequest._();
  @$core.override
  RectifyDeclarationRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RectifyDeclarationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RectifyDeclarationRequest>(create);
  static RectifyDeclarationRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get jsonPayload => $_getSZ(0);
  @$pb.TagNumber(1)
  set jsonPayload($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasJsonPayload() => $_has(0);
  @$pb.TagNumber(1)
  void clearJsonPayload() => $_clearField(1);
}

class UploadDocumentRequest extends $pb.GeneratedMessage {
  factory UploadDocumentRequest({
    $core.String? declarationId,
    $core.String? docCode,
    $core.String? docReference,
    $core.List<$core.int>? fileContent,
    $core.String? fileName,
    $core.String? contentType,
  }) {
    final result = create();
    if (declarationId != null) result.declarationId = declarationId;
    if (docCode != null) result.docCode = docCode;
    if (docReference != null) result.docReference = docReference;
    if (fileContent != null) result.fileContent = fileContent;
    if (fileName != null) result.fileName = fileName;
    if (contentType != null) result.contentType = contentType;
    return result;
  }

  UploadDocumentRequest._();

  factory UploadDocumentRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UploadDocumentRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UploadDocumentRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'aduanext.hacienda'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'declarationId')
    ..aOS(2, _omitFieldNames ? '' : 'docCode')
    ..aOS(3, _omitFieldNames ? '' : 'docReference')
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'fileContent', $pb.PbFieldType.OY)
    ..aOS(5, _omitFieldNames ? '' : 'fileName')
    ..aOS(6, _omitFieldNames ? '' : 'contentType')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadDocumentRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadDocumentRequest copyWith(
          void Function(UploadDocumentRequest) updates) =>
      super.copyWith((message) => updates(message as UploadDocumentRequest))
          as UploadDocumentRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UploadDocumentRequest create() => UploadDocumentRequest._();
  @$core.override
  UploadDocumentRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UploadDocumentRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UploadDocumentRequest>(create);
  static UploadDocumentRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get declarationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set declarationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeclarationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeclarationId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get docCode => $_getSZ(1);
  @$pb.TagNumber(2)
  set docCode($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDocCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearDocCode() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get docReference => $_getSZ(2);
  @$pb.TagNumber(3)
  set docReference($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDocReference() => $_has(2);
  @$pb.TagNumber(3)
  void clearDocReference() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get fileContent => $_getN(3);
  @$pb.TagNumber(4)
  set fileContent($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFileContent() => $_has(3);
  @$pb.TagNumber(4)
  void clearFileContent() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get fileName => $_getSZ(4);
  @$pb.TagNumber(5)
  set fileName($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasFileName() => $_has(4);
  @$pb.TagNumber(5)
  void clearFileName() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get contentType => $_getSZ(5);
  @$pb.TagNumber(6)
  set contentType($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasContentType() => $_has(5);
  @$pb.TagNumber(6)
  void clearContentType() => $_clearField(6);
}

class ApiResponse extends $pb.GeneratedMessage {
  factory ApiResponse({
    $core.int? httpStatus,
    $core.String? jsonPayload,
    $core.String? error,
  }) {
    final result = create();
    if (httpStatus != null) result.httpStatus = httpStatus;
    if (jsonPayload != null) result.jsonPayload = jsonPayload;
    if (error != null) result.error = error;
    return result;
  }

  ApiResponse._();

  factory ApiResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ApiResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ApiResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'aduanext.hacienda'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'httpStatus')
    ..aOS(2, _omitFieldNames ? '' : 'jsonPayload')
    ..aOS(3, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApiResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApiResponse copyWith(void Function(ApiResponse) updates) =>
      super.copyWith((message) => updates(message as ApiResponse))
          as ApiResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApiResponse create() => ApiResponse._();
  @$core.override
  ApiResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ApiResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ApiResponse>(create);
  static ApiResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get httpStatus => $_getIZ(0);
  @$pb.TagNumber(1)
  set httpStatus($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasHttpStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearHttpStatus() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get jsonPayload => $_getSZ(1);
  @$pb.TagNumber(2)
  set jsonPayload($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasJsonPayload() => $_has(1);
  @$pb.TagNumber(2)
  void clearJsonPayload() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get error => $_getSZ(2);
  @$pb.TagNumber(3)
  set error($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasError() => $_has(2);
  @$pb.TagNumber(3)
  void clearError() => $_clearField(3);
}

class RimmSearchRequest extends $pb.GeneratedMessage {
  factory RimmSearchRequest({
    $core.String? endpoint,
    $core.Iterable<RimmRestriction>? restrictions,
    RimmMeta? meta,
    $core.int? max,
    $core.int? offset,
    $core.bool? distinct,
    $core.String? restrictBy,
    $core.Iterable<$core.String>? selectFields,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? sortByFields,
  }) {
    final result = create();
    if (endpoint != null) result.endpoint = endpoint;
    if (restrictions != null) result.restrictions.addAll(restrictions);
    if (meta != null) result.meta = meta;
    if (max != null) result.max = max;
    if (offset != null) result.offset = offset;
    if (distinct != null) result.distinct = distinct;
    if (restrictBy != null) result.restrictBy = restrictBy;
    if (selectFields != null) result.selectFields.addAll(selectFields);
    if (sortByFields != null) result.sortByFields.addEntries(sortByFields);
    return result;
  }

  RimmSearchRequest._();

  factory RimmSearchRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RimmSearchRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RimmSearchRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'aduanext.hacienda'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'endpoint')
    ..pPM<RimmRestriction>(2, _omitFieldNames ? '' : 'restrictions',
        subBuilder: RimmRestriction.create)
    ..aOM<RimmMeta>(3, _omitFieldNames ? '' : 'meta',
        subBuilder: RimmMeta.create)
    ..aI(4, _omitFieldNames ? '' : 'max')
    ..aI(5, _omitFieldNames ? '' : 'offset')
    ..aOB(6, _omitFieldNames ? '' : 'distinct')
    ..aOS(7, _omitFieldNames ? '' : 'restrictBy')
    ..pPS(8, _omitFieldNames ? '' : 'selectFields')
    ..m<$core.String, $core.String>(9, _omitFieldNames ? '' : 'sortByFields',
        entryClassName: 'RimmSearchRequest.SortByFieldsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('aduanext.hacienda'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RimmSearchRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RimmSearchRequest copyWith(void Function(RimmSearchRequest) updates) =>
      super.copyWith((message) => updates(message as RimmSearchRequest))
          as RimmSearchRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RimmSearchRequest create() => RimmSearchRequest._();
  @$core.override
  RimmSearchRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RimmSearchRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RimmSearchRequest>(create);
  static RimmSearchRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get endpoint => $_getSZ(0);
  @$pb.TagNumber(1)
  set endpoint($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEndpoint() => $_has(0);
  @$pb.TagNumber(1)
  void clearEndpoint() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<RimmRestriction> get restrictions => $_getList(1);

  @$pb.TagNumber(3)
  RimmMeta get meta => $_getN(2);
  @$pb.TagNumber(3)
  set meta(RimmMeta value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasMeta() => $_has(2);
  @$pb.TagNumber(3)
  void clearMeta() => $_clearField(3);
  @$pb.TagNumber(3)
  RimmMeta ensureMeta() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.int get max => $_getIZ(3);
  @$pb.TagNumber(4)
  set max($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMax() => $_has(3);
  @$pb.TagNumber(4)
  void clearMax() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get offset => $_getIZ(4);
  @$pb.TagNumber(5)
  set offset($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasOffset() => $_has(4);
  @$pb.TagNumber(5)
  void clearOffset() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get distinct => $_getBF(5);
  @$pb.TagNumber(6)
  set distinct($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDistinct() => $_has(5);
  @$pb.TagNumber(6)
  void clearDistinct() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get restrictBy => $_getSZ(6);
  @$pb.TagNumber(7)
  set restrictBy($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasRestrictBy() => $_has(6);
  @$pb.TagNumber(7)
  void clearRestrictBy() => $_clearField(7);

  @$pb.TagNumber(8)
  $pb.PbList<$core.String> get selectFields => $_getList(7);

  @$pb.TagNumber(9)
  $pb.PbMap<$core.String, $core.String> get sortByFields => $_getMap(8);
}

class RimmRestriction extends $pb.GeneratedMessage {
  factory RimmRestriction({
    $core.String? value,
    $core.String? operator,
    $core.String? field_3,
    $core.String? valueTo,
  }) {
    final result = create();
    if (value != null) result.value = value;
    if (operator != null) result.operator = operator;
    if (field_3 != null) result.field_3 = field_3;
    if (valueTo != null) result.valueTo = valueTo;
    return result;
  }

  RimmRestriction._();

  factory RimmRestriction.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RimmRestriction.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RimmRestriction',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'aduanext.hacienda'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'value')
    ..aOS(2, _omitFieldNames ? '' : 'operator')
    ..aOS(3, _omitFieldNames ? '' : 'field')
    ..aOS(4, _omitFieldNames ? '' : 'valueTo')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RimmRestriction clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RimmRestriction copyWith(void Function(RimmRestriction) updates) =>
      super.copyWith((message) => updates(message as RimmRestriction))
          as RimmRestriction;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RimmRestriction create() => RimmRestriction._();
  @$core.override
  RimmRestriction createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RimmRestriction getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RimmRestriction>(create);
  static RimmRestriction? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get value => $_getSZ(0);
  @$pb.TagNumber(1)
  set value($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get operator => $_getSZ(1);
  @$pb.TagNumber(2)
  set operator($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOperator() => $_has(1);
  @$pb.TagNumber(2)
  void clearOperator() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get field_3 => $_getSZ(2);
  @$pb.TagNumber(3)
  set field_3($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasField_3() => $_has(2);
  @$pb.TagNumber(3)
  void clearField_3() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get valueTo => $_getSZ(3);
  @$pb.TagNumber(4)
  set valueTo($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasValueTo() => $_has(3);
  @$pb.TagNumber(4)
  void clearValueTo() => $_clearField(4);
}

class RimmMeta extends $pb.GeneratedMessage {
  factory RimmMeta({
    $core.String? operator,
    $core.String? validityDate,
  }) {
    final result = create();
    if (operator != null) result.operator = operator;
    if (validityDate != null) result.validityDate = validityDate;
    return result;
  }

  RimmMeta._();

  factory RimmMeta.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RimmMeta.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RimmMeta',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'aduanext.hacienda'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'operator')
    ..aOS(2, _omitFieldNames ? '' : 'validityDate')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RimmMeta clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RimmMeta copyWith(void Function(RimmMeta) updates) =>
      super.copyWith((message) => updates(message as RimmMeta)) as RimmMeta;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RimmMeta create() => RimmMeta._();
  @$core.override
  RimmMeta createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RimmMeta getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RimmMeta>(create);
  static RimmMeta? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get operator => $_getSZ(0);
  @$pb.TagNumber(1)
  set operator($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOperator() => $_has(0);
  @$pb.TagNumber(1)
  void clearOperator() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get validityDate => $_getSZ(1);
  @$pb.TagNumber(2)
  set validityDate($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasValidityDate() => $_has(1);
  @$pb.TagNumber(2)
  void clearValidityDate() => $_clearField(2);
}

class RimmSearchResponse extends $pb.GeneratedMessage {
  factory RimmSearchResponse({
    $core.Iterable<$core.String>? resultList,
    $core.int? totalCount,
    $core.String? error,
  }) {
    final result = create();
    if (resultList != null) result.resultList.addAll(resultList);
    if (totalCount != null) result.totalCount = totalCount;
    if (error != null) result.error = error;
    return result;
  }

  RimmSearchResponse._();

  factory RimmSearchResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RimmSearchResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RimmSearchResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'aduanext.hacienda'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'resultList')
    ..aI(2, _omitFieldNames ? '' : 'totalCount')
    ..aOS(3, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RimmSearchResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RimmSearchResponse copyWith(void Function(RimmSearchResponse) updates) =>
      super.copyWith((message) => updates(message as RimmSearchResponse))
          as RimmSearchResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RimmSearchResponse create() => RimmSearchResponse._();
  @$core.override
  RimmSearchResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RimmSearchResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RimmSearchResponse>(create);
  static RimmSearchResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get resultList => $_getList(0);

  @$pb.TagNumber(2)
  $core.int get totalCount => $_getIZ(1);
  @$pb.TagNumber(2)
  set totalCount($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTotalCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearTotalCount() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get error => $_getSZ(2);
  @$pb.TagNumber(3)
  set error($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasError() => $_has(2);
  @$pb.TagNumber(3)
  void clearError() => $_clearField(3);
}

class SubmitSignedDeclarationRequest extends $pb.GeneratedMessage {
  factory SubmitSignedDeclarationRequest({
    $core.String? jsonPayload,
    $core.List<$core.int>? p12Buffer,
    $core.String? p12Pin,
    AuthenticateRequest? auth,
    $core.bool? validateOnly,
  }) {
    final result = create();
    if (jsonPayload != null) result.jsonPayload = jsonPayload;
    if (p12Buffer != null) result.p12Buffer = p12Buffer;
    if (p12Pin != null) result.p12Pin = p12Pin;
    if (auth != null) result.auth = auth;
    if (validateOnly != null) result.validateOnly = validateOnly;
    return result;
  }

  SubmitSignedDeclarationRequest._();

  factory SubmitSignedDeclarationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SubmitSignedDeclarationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubmitSignedDeclarationRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'aduanext.hacienda'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'jsonPayload')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'p12Buffer', $pb.PbFieldType.OY)
    ..aOS(3, _omitFieldNames ? '' : 'p12Pin')
    ..aOM<AuthenticateRequest>(4, _omitFieldNames ? '' : 'auth',
        subBuilder: AuthenticateRequest.create)
    ..aOB(5, _omitFieldNames ? '' : 'validateOnly')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubmitSignedDeclarationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubmitSignedDeclarationRequest copyWith(
          void Function(SubmitSignedDeclarationRequest) updates) =>
      super.copyWith(
              (message) => updates(message as SubmitSignedDeclarationRequest))
          as SubmitSignedDeclarationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SubmitSignedDeclarationRequest create() =>
      SubmitSignedDeclarationRequest._();
  @$core.override
  SubmitSignedDeclarationRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SubmitSignedDeclarationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubmitSignedDeclarationRequest>(create);
  static SubmitSignedDeclarationRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get jsonPayload => $_getSZ(0);
  @$pb.TagNumber(1)
  set jsonPayload($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasJsonPayload() => $_has(0);
  @$pb.TagNumber(1)
  void clearJsonPayload() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get p12Buffer => $_getN(1);
  @$pb.TagNumber(2)
  set p12Buffer($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasP12Buffer() => $_has(1);
  @$pb.TagNumber(2)
  void clearP12Buffer() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get p12Pin => $_getSZ(2);
  @$pb.TagNumber(3)
  set p12Pin($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasP12Pin() => $_has(2);
  @$pb.TagNumber(3)
  void clearP12Pin() => $_clearField(3);

  @$pb.TagNumber(4)
  AuthenticateRequest get auth => $_getN(3);
  @$pb.TagNumber(4)
  set auth(AuthenticateRequest value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasAuth() => $_has(3);
  @$pb.TagNumber(4)
  void clearAuth() => $_clearField(4);
  @$pb.TagNumber(4)
  AuthenticateRequest ensureAuth() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.bool get validateOnly => $_getBF(4);
  @$pb.TagNumber(5)
  set validateOnly($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasValidateOnly() => $_has(4);
  @$pb.TagNumber(5)
  void clearValidateOnly() => $_clearField(5);
}

class SubmitSignedDeclarationResponse extends $pb.GeneratedMessage {
  factory SubmitSignedDeclarationResponse({
    $core.bool? success,
    $core.String? status,
    $core.String? customsRegistrationNumber,
    $core.String? assessmentSerial,
    $core.int? assessmentNumber,
    $core.String? assessmentDate,
    $core.String? jsonResponse,
    $core.String? error,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (status != null) result.status = status;
    if (customsRegistrationNumber != null)
      result.customsRegistrationNumber = customsRegistrationNumber;
    if (assessmentSerial != null) result.assessmentSerial = assessmentSerial;
    if (assessmentNumber != null) result.assessmentNumber = assessmentNumber;
    if (assessmentDate != null) result.assessmentDate = assessmentDate;
    if (jsonResponse != null) result.jsonResponse = jsonResponse;
    if (error != null) result.error = error;
    return result;
  }

  SubmitSignedDeclarationResponse._();

  factory SubmitSignedDeclarationResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SubmitSignedDeclarationResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubmitSignedDeclarationResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'aduanext.hacienda'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'status')
    ..aOS(3, _omitFieldNames ? '' : 'customsRegistrationNumber')
    ..aOS(4, _omitFieldNames ? '' : 'assessmentSerial')
    ..aI(5, _omitFieldNames ? '' : 'assessmentNumber')
    ..aOS(6, _omitFieldNames ? '' : 'assessmentDate')
    ..aOS(7, _omitFieldNames ? '' : 'jsonResponse')
    ..aOS(8, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubmitSignedDeclarationResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubmitSignedDeclarationResponse copyWith(
          void Function(SubmitSignedDeclarationResponse) updates) =>
      super.copyWith(
              (message) => updates(message as SubmitSignedDeclarationResponse))
          as SubmitSignedDeclarationResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SubmitSignedDeclarationResponse create() =>
      SubmitSignedDeclarationResponse._();
  @$core.override
  SubmitSignedDeclarationResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SubmitSignedDeclarationResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubmitSignedDeclarationResponse>(
          create);
  static SubmitSignedDeclarationResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get status => $_getSZ(1);
  @$pb.TagNumber(2)
  set status($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get customsRegistrationNumber => $_getSZ(2);
  @$pb.TagNumber(3)
  set customsRegistrationNumber($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCustomsRegistrationNumber() => $_has(2);
  @$pb.TagNumber(3)
  void clearCustomsRegistrationNumber() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get assessmentSerial => $_getSZ(3);
  @$pb.TagNumber(4)
  set assessmentSerial($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAssessmentSerial() => $_has(3);
  @$pb.TagNumber(4)
  void clearAssessmentSerial() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get assessmentNumber => $_getIZ(4);
  @$pb.TagNumber(5)
  set assessmentNumber($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAssessmentNumber() => $_has(4);
  @$pb.TagNumber(5)
  void clearAssessmentNumber() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get assessmentDate => $_getSZ(5);
  @$pb.TagNumber(6)
  set assessmentDate($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAssessmentDate() => $_has(5);
  @$pb.TagNumber(6)
  void clearAssessmentDate() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get jsonResponse => $_getSZ(6);
  @$pb.TagNumber(7)
  set jsonResponse($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasJsonResponse() => $_has(6);
  @$pb.TagNumber(7)
  void clearJsonResponse() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get error => $_getSZ(7);
  @$pb.TagNumber(8)
  set error($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasError() => $_has(7);
  @$pb.TagNumber(8)
  void clearError() => $_clearField(8);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
