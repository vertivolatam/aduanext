// This is a generated file - do not edit.
//
// Generated from hacienda.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use authenticateRequestDescriptor instead')
const AuthenticateRequest$json = {
  '1': 'AuthenticateRequest',
  '2': [
    {'1': 'id_type', '3': 1, '4': 1, '5': 9, '10': 'idType'},
    {'1': 'id_number', '3': 2, '4': 1, '5': 9, '10': 'idNumber'},
    {'1': 'password', '3': 3, '4': 1, '5': 9, '10': 'password'},
    {'1': 'client_id', '3': 4, '4': 1, '5': 9, '10': 'clientId'},
    {'1': 'environment', '3': 5, '4': 1, '5': 9, '10': 'environment'},
  ],
};

/// Descriptor for `AuthenticateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List authenticateRequestDescriptor = $convert.base64Decode(
    'ChNBdXRoZW50aWNhdGVSZXF1ZXN0EhcKB2lkX3R5cGUYASABKAlSBmlkVHlwZRIbCglpZF9udW'
    '1iZXIYAiABKAlSCGlkTnVtYmVyEhoKCHBhc3N3b3JkGAMgASgJUghwYXNzd29yZBIbCgljbGll'
    'bnRfaWQYBCABKAlSCGNsaWVudElkEiAKC2Vudmlyb25tZW50GAUgASgJUgtlbnZpcm9ubWVudA'
    '==');

@$core.Deprecated('Use authenticateResponseDescriptor instead')
const AuthenticateResponse$json = {
  '1': 'AuthenticateResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'error_code', '3': 3, '4': 1, '5': 9, '10': 'errorCode'},
  ],
};

/// Descriptor for `AuthenticateResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List authenticateResponseDescriptor = $convert.base64Decode(
    'ChRBdXRoZW50aWNhdGVSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEhgKB21lc3'
    'NhZ2UYAiABKAlSB21lc3NhZ2USHQoKZXJyb3JfY29kZRgDIAEoCVIJZXJyb3JDb2Rl');

@$core.Deprecated('Use getAccessTokenRequestDescriptor instead')
const GetAccessTokenRequest$json = {
  '1': 'GetAccessTokenRequest',
  '2': [
    {'1': 'client_id', '3': 1, '4': 1, '5': 9, '10': 'clientId'},
  ],
};

/// Descriptor for `GetAccessTokenRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getAccessTokenRequestDescriptor = $convert.base64Decode(
    'ChVHZXRBY2Nlc3NUb2tlblJlcXVlc3QSGwoJY2xpZW50X2lkGAEgASgJUghjbGllbnRJZA==');

@$core.Deprecated('Use getAccessTokenResponseDescriptor instead')
const GetAccessTokenResponse$json = {
  '1': 'GetAccessTokenResponse',
  '2': [
    {'1': 'token', '3': 1, '4': 1, '5': 9, '10': 'token'},
    {
      '1': 'expires_in_seconds',
      '3': 2,
      '4': 1,
      '5': 3,
      '10': 'expiresInSeconds'
    },
    {'1': 'token_type', '3': 3, '4': 1, '5': 9, '10': 'tokenType'},
    {'1': 'scope', '3': 4, '4': 1, '5': 9, '10': 'scope'},
  ],
};

/// Descriptor for `GetAccessTokenResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getAccessTokenResponseDescriptor = $convert.base64Decode(
    'ChZHZXRBY2Nlc3NUb2tlblJlc3BvbnNlEhQKBXRva2VuGAEgASgJUgV0b2tlbhIsChJleHBpcm'
    'VzX2luX3NlY29uZHMYAiABKANSEGV4cGlyZXNJblNlY29uZHMSHQoKdG9rZW5fdHlwZRgDIAEo'
    'CVIJdG9rZW5UeXBlEhQKBXNjb3BlGAQgASgJUgVzY29wZQ==');

@$core.Deprecated('Use isAuthenticatedRequestDescriptor instead')
const IsAuthenticatedRequest$json = {
  '1': 'IsAuthenticatedRequest',
  '2': [
    {'1': 'client_id', '3': 1, '4': 1, '5': 9, '10': 'clientId'},
  ],
};

/// Descriptor for `IsAuthenticatedRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List isAuthenticatedRequestDescriptor =
    $convert.base64Decode(
        'ChZJc0F1dGhlbnRpY2F0ZWRSZXF1ZXN0EhsKCWNsaWVudF9pZBgBIAEoCVIIY2xpZW50SWQ=');

@$core.Deprecated('Use isAuthenticatedResponseDescriptor instead')
const IsAuthenticatedResponse$json = {
  '1': 'IsAuthenticatedResponse',
  '2': [
    {'1': 'authenticated', '3': 1, '4': 1, '5': 8, '10': 'authenticated'},
  ],
};

/// Descriptor for `IsAuthenticatedResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List isAuthenticatedResponseDescriptor =
    $convert.base64Decode(
        'ChdJc0F1dGhlbnRpY2F0ZWRSZXNwb25zZRIkCg1hdXRoZW50aWNhdGVkGAEgASgIUg1hdXRoZW'
        '50aWNhdGVk');

@$core.Deprecated('Use invalidateRequestDescriptor instead')
const InvalidateRequest$json = {
  '1': 'InvalidateRequest',
  '2': [
    {'1': 'client_id', '3': 1, '4': 1, '5': 9, '10': 'clientId'},
  ],
};

/// Descriptor for `InvalidateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List invalidateRequestDescriptor = $convert.base64Decode(
    'ChFJbnZhbGlkYXRlUmVxdWVzdBIbCgljbGllbnRfaWQYASABKAlSCGNsaWVudElk');

@$core.Deprecated('Use invalidateResponseDescriptor instead')
const InvalidateResponse$json = {
  '1': 'InvalidateResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
  ],
};

/// Descriptor for `InvalidateResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List invalidateResponseDescriptor =
    $convert.base64Decode(
        'ChJJbnZhbGlkYXRlUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2Vzcw==');

@$core.Deprecated('Use signXmlRequestDescriptor instead')
const SignXmlRequest$json = {
  '1': 'SignXmlRequest',
  '2': [
    {'1': 'xml', '3': 1, '4': 1, '5': 9, '10': 'xml'},
    {'1': 'p12_buffer', '3': 2, '4': 1, '5': 12, '10': 'p12Buffer'},
    {'1': 'p12_pin', '3': 3, '4': 1, '5': 9, '10': 'p12Pin'},
  ],
};

/// Descriptor for `SignXmlRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signXmlRequestDescriptor = $convert.base64Decode(
    'Cg5TaWduWG1sUmVxdWVzdBIQCgN4bWwYASABKAlSA3htbBIdCgpwMTJfYnVmZmVyGAIgASgMUg'
    'lwMTJCdWZmZXISFwoHcDEyX3BpbhgDIAEoCVIGcDEyUGlu');

@$core.Deprecated('Use signXmlResponseDescriptor instead')
const SignXmlResponse$json = {
  '1': 'SignXmlResponse',
  '2': [
    {'1': 'signed_xml', '3': 1, '4': 1, '5': 9, '10': 'signedXml'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `SignXmlResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signXmlResponseDescriptor = $convert.base64Decode(
    'Cg9TaWduWG1sUmVzcG9uc2USHQoKc2lnbmVkX3htbBgBIAEoCVIJc2lnbmVkWG1sEhQKBWVycm'
    '9yGAIgASgJUgVlcnJvcg==');

@$core.Deprecated('Use signAndEncodeRequestDescriptor instead')
const SignAndEncodeRequest$json = {
  '1': 'SignAndEncodeRequest',
  '2': [
    {'1': 'xml', '3': 1, '4': 1, '5': 9, '10': 'xml'},
    {'1': 'p12_buffer', '3': 2, '4': 1, '5': 12, '10': 'p12Buffer'},
    {'1': 'p12_pin', '3': 3, '4': 1, '5': 9, '10': 'p12Pin'},
  ],
};

/// Descriptor for `SignAndEncodeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signAndEncodeRequestDescriptor = $convert.base64Decode(
    'ChRTaWduQW5kRW5jb2RlUmVxdWVzdBIQCgN4bWwYASABKAlSA3htbBIdCgpwMTJfYnVmZmVyGA'
    'IgASgMUglwMTJCdWZmZXISFwoHcDEyX3BpbhgDIAEoCVIGcDEyUGlu');

@$core.Deprecated('Use signAndEncodeResponseDescriptor instead')
const SignAndEncodeResponse$json = {
  '1': 'SignAndEncodeResponse',
  '2': [
    {'1': 'base64_signed_xml', '3': 1, '4': 1, '5': 9, '10': 'base64SignedXml'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `SignAndEncodeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signAndEncodeResponseDescriptor = $convert.base64Decode(
    'ChVTaWduQW5kRW5jb2RlUmVzcG9uc2USKgoRYmFzZTY0X3NpZ25lZF94bWwYASABKAlSD2Jhc2'
    'U2NFNpZ25lZFhtbBIUCgVlcnJvchgCIAEoCVIFZXJyb3I=');

@$core.Deprecated('Use verifySignatureRequestDescriptor instead')
const VerifySignatureRequest$json = {
  '1': 'VerifySignatureRequest',
  '2': [
    {'1': 'signed_xml', '3': 1, '4': 1, '5': 9, '10': 'signedXml'},
  ],
};

/// Descriptor for `VerifySignatureRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List verifySignatureRequestDescriptor =
    $convert.base64Decode(
        'ChZWZXJpZnlTaWduYXR1cmVSZXF1ZXN0Eh0KCnNpZ25lZF94bWwYASABKAlSCXNpZ25lZFhtbA'
        '==');

@$core.Deprecated('Use verifySignatureResponseDescriptor instead')
const VerifySignatureResponse$json = {
  '1': 'VerifySignatureResponse',
  '2': [
    {'1': 'valid', '3': 1, '4': 1, '5': 8, '10': 'valid'},
    {'1': 'signer_cn', '3': 2, '4': 1, '5': 9, '10': 'signerCn'},
    {'1': 'error', '3': 3, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `VerifySignatureResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List verifySignatureResponseDescriptor =
    $convert.base64Decode(
        'ChdWZXJpZnlTaWduYXR1cmVSZXNwb25zZRIUCgV2YWxpZBgBIAEoCFIFdmFsaWQSGwoJc2lnbm'
        'VyX2NuGAIgASgJUghzaWduZXJDbhIUCgVlcnJvchgDIAEoCVIFZXJyb3I=');

@$core.Deprecated('Use getDeclarationRequestDescriptor instead')
const GetDeclarationRequest$json = {
  '1': 'GetDeclarationRequest',
  '2': [
    {
      '1': 'customs_office_code',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'customsOfficeCode'
    },
    {'1': 'serial', '3': 2, '4': 1, '5': 9, '10': 'serial'},
    {'1': 'number', '3': 3, '4': 1, '5': 5, '10': 'number'},
    {'1': 'year', '3': 4, '4': 1, '5': 5, '10': 'year'},
  ],
};

/// Descriptor for `GetDeclarationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getDeclarationRequestDescriptor = $convert.base64Decode(
    'ChVHZXREZWNsYXJhdGlvblJlcXVlc3QSLgoTY3VzdG9tc19vZmZpY2VfY29kZRgBIAEoCVIRY3'
    'VzdG9tc09mZmljZUNvZGUSFgoGc2VyaWFsGAIgASgJUgZzZXJpYWwSFgoGbnVtYmVyGAMgASgF'
    'UgZudW1iZXISEgoEeWVhchgEIAEoBVIEeWVhcg==');

@$core.Deprecated('Use getDeclarationResponseDescriptor instead')
const GetDeclarationResponse$json = {
  '1': 'GetDeclarationResponse',
  '2': [
    {'1': 'json_payload', '3': 1, '4': 1, '5': 9, '10': 'jsonPayload'},
    {'1': 'http_status', '3': 2, '4': 1, '5': 5, '10': 'httpStatus'},
    {'1': 'error', '3': 3, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `GetDeclarationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getDeclarationResponseDescriptor = $convert.base64Decode(
    'ChZHZXREZWNsYXJhdGlvblJlc3BvbnNlEiEKDGpzb25fcGF5bG9hZBgBIAEoCVILanNvblBheW'
    'xvYWQSHwoLaHR0cF9zdGF0dXMYAiABKAVSCmh0dHBTdGF0dXMSFAoFZXJyb3IYAyABKAlSBWVy'
    'cm9y');

@$core.Deprecated('Use validateDeclarationRequestDescriptor instead')
const ValidateDeclarationRequest$json = {
  '1': 'ValidateDeclarationRequest',
  '2': [
    {'1': 'json_payload', '3': 1, '4': 1, '5': 9, '10': 'jsonPayload'},
  ],
};

/// Descriptor for `ValidateDeclarationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List validateDeclarationRequestDescriptor =
    $convert.base64Decode(
        'ChpWYWxpZGF0ZURlY2xhcmF0aW9uUmVxdWVzdBIhCgxqc29uX3BheWxvYWQYASABKAlSC2pzb2'
        '5QYXlsb2Fk');

@$core.Deprecated('Use liquidateDeclarationRequestDescriptor instead')
const LiquidateDeclarationRequest$json = {
  '1': 'LiquidateDeclarationRequest',
  '2': [
    {'1': 'json_payload', '3': 1, '4': 1, '5': 9, '10': 'jsonPayload'},
  ],
};

/// Descriptor for `LiquidateDeclarationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List liquidateDeclarationRequestDescriptor =
    $convert.base64Decode(
        'ChtMaXF1aWRhdGVEZWNsYXJhdGlvblJlcXVlc3QSIQoManNvbl9wYXlsb2FkGAEgASgJUgtqc2'
        '9uUGF5bG9hZA==');

@$core.Deprecated('Use validateRectificationRequestDescriptor instead')
const ValidateRectificationRequest$json = {
  '1': 'ValidateRectificationRequest',
  '2': [
    {'1': 'json_payload', '3': 1, '4': 1, '5': 9, '10': 'jsonPayload'},
  ],
};

/// Descriptor for `ValidateRectificationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List validateRectificationRequestDescriptor =
    $convert.base64Decode(
        'ChxWYWxpZGF0ZVJlY3RpZmljYXRpb25SZXF1ZXN0EiEKDGpzb25fcGF5bG9hZBgBIAEoCVILan'
        'NvblBheWxvYWQ=');

@$core.Deprecated('Use rectifyDeclarationRequestDescriptor instead')
const RectifyDeclarationRequest$json = {
  '1': 'RectifyDeclarationRequest',
  '2': [
    {'1': 'json_payload', '3': 1, '4': 1, '5': 9, '10': 'jsonPayload'},
  ],
};

/// Descriptor for `RectifyDeclarationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rectifyDeclarationRequestDescriptor =
    $convert.base64Decode(
        'ChlSZWN0aWZ5RGVjbGFyYXRpb25SZXF1ZXN0EiEKDGpzb25fcGF5bG9hZBgBIAEoCVILanNvbl'
        'BheWxvYWQ=');

@$core.Deprecated('Use uploadDocumentRequestDescriptor instead')
const UploadDocumentRequest$json = {
  '1': 'UploadDocumentRequest',
  '2': [
    {'1': 'declaration_id', '3': 1, '4': 1, '5': 9, '10': 'declarationId'},
    {'1': 'doc_code', '3': 2, '4': 1, '5': 9, '10': 'docCode'},
    {'1': 'doc_reference', '3': 3, '4': 1, '5': 9, '10': 'docReference'},
    {'1': 'file_content', '3': 4, '4': 1, '5': 12, '10': 'fileContent'},
    {'1': 'file_name', '3': 5, '4': 1, '5': 9, '10': 'fileName'},
    {'1': 'content_type', '3': 6, '4': 1, '5': 9, '10': 'contentType'},
  ],
};

/// Descriptor for `UploadDocumentRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List uploadDocumentRequestDescriptor = $convert.base64Decode(
    'ChVVcGxvYWREb2N1bWVudFJlcXVlc3QSJQoOZGVjbGFyYXRpb25faWQYASABKAlSDWRlY2xhcm'
    'F0aW9uSWQSGQoIZG9jX2NvZGUYAiABKAlSB2RvY0NvZGUSIwoNZG9jX3JlZmVyZW5jZRgDIAEo'
    'CVIMZG9jUmVmZXJlbmNlEiEKDGZpbGVfY29udGVudBgEIAEoDFILZmlsZUNvbnRlbnQSGwoJZm'
    'lsZV9uYW1lGAUgASgJUghmaWxlTmFtZRIhCgxjb250ZW50X3R5cGUYBiABKAlSC2NvbnRlbnRU'
    'eXBl');

@$core.Deprecated('Use apiResponseDescriptor instead')
const ApiResponse$json = {
  '1': 'ApiResponse',
  '2': [
    {'1': 'http_status', '3': 1, '4': 1, '5': 5, '10': 'httpStatus'},
    {'1': 'json_payload', '3': 2, '4': 1, '5': 9, '10': 'jsonPayload'},
    {'1': 'error', '3': 3, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `ApiResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List apiResponseDescriptor = $convert.base64Decode(
    'CgtBcGlSZXNwb25zZRIfCgtodHRwX3N0YXR1cxgBIAEoBVIKaHR0cFN0YXR1cxIhCgxqc29uX3'
    'BheWxvYWQYAiABKAlSC2pzb25QYXlsb2FkEhQKBWVycm9yGAMgASgJUgVlcnJvcg==');

@$core.Deprecated('Use rimmSearchRequestDescriptor instead')
const RimmSearchRequest$json = {
  '1': 'RimmSearchRequest',
  '2': [
    {'1': 'endpoint', '3': 1, '4': 1, '5': 9, '10': 'endpoint'},
    {
      '1': 'restrictions',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.aduanext.hacienda.RimmRestriction',
      '10': 'restrictions'
    },
    {
      '1': 'meta',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.aduanext.hacienda.RimmMeta',
      '10': 'meta'
    },
    {'1': 'max', '3': 4, '4': 1, '5': 5, '10': 'max'},
    {'1': 'offset', '3': 5, '4': 1, '5': 5, '10': 'offset'},
    {'1': 'distinct', '3': 6, '4': 1, '5': 8, '10': 'distinct'},
    {'1': 'restrict_by', '3': 7, '4': 1, '5': 9, '10': 'restrictBy'},
    {'1': 'select_fields', '3': 8, '4': 3, '5': 9, '10': 'selectFields'},
    {
      '1': 'sort_by_fields',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.aduanext.hacienda.RimmSearchRequest.SortByFieldsEntry',
      '10': 'sortByFields'
    },
  ],
  '3': [RimmSearchRequest_SortByFieldsEntry$json],
};

@$core.Deprecated('Use rimmSearchRequestDescriptor instead')
const RimmSearchRequest_SortByFieldsEntry$json = {
  '1': 'SortByFieldsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `RimmSearchRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rimmSearchRequestDescriptor = $convert.base64Decode(
    'ChFSaW1tU2VhcmNoUmVxdWVzdBIaCghlbmRwb2ludBgBIAEoCVIIZW5kcG9pbnQSRgoMcmVzdH'
    'JpY3Rpb25zGAIgAygLMiIuYWR1YW5leHQuaGFjaWVuZGEuUmltbVJlc3RyaWN0aW9uUgxyZXN0'
    'cmljdGlvbnMSLwoEbWV0YRgDIAEoCzIbLmFkdWFuZXh0LmhhY2llbmRhLlJpbW1NZXRhUgRtZX'
    'RhEhAKA21heBgEIAEoBVIDbWF4EhYKBm9mZnNldBgFIAEoBVIGb2Zmc2V0EhoKCGRpc3RpbmN0'
    'GAYgASgIUghkaXN0aW5jdBIfCgtyZXN0cmljdF9ieRgHIAEoCVIKcmVzdHJpY3RCeRIjCg1zZW'
    'xlY3RfZmllbGRzGAggAygJUgxzZWxlY3RGaWVsZHMSXAoOc29ydF9ieV9maWVsZHMYCSADKAsy'
    'Ni5hZHVhbmV4dC5oYWNpZW5kYS5SaW1tU2VhcmNoUmVxdWVzdC5Tb3J0QnlGaWVsZHNFbnRyeV'
    'IMc29ydEJ5RmllbGRzGj8KEVNvcnRCeUZpZWxkc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQK'
    'BXZhbHVlGAIgASgJUgV2YWx1ZToCOAE=');

@$core.Deprecated('Use rimmRestrictionDescriptor instead')
const RimmRestriction$json = {
  '1': 'RimmRestriction',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 9, '10': 'value'},
    {'1': 'operator', '3': 2, '4': 1, '5': 9, '10': 'operator'},
    {'1': 'field', '3': 3, '4': 1, '5': 9, '10': 'field'},
    {'1': 'value_to', '3': 4, '4': 1, '5': 9, '10': 'valueTo'},
  ],
};

/// Descriptor for `RimmRestriction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rimmRestrictionDescriptor = $convert.base64Decode(
    'Cg9SaW1tUmVzdHJpY3Rpb24SFAoFdmFsdWUYASABKAlSBXZhbHVlEhoKCG9wZXJhdG9yGAIgAS'
    'gJUghvcGVyYXRvchIUCgVmaWVsZBgDIAEoCVIFZmllbGQSGQoIdmFsdWVfdG8YBCABKAlSB3Zh'
    'bHVlVG8=');

@$core.Deprecated('Use rimmMetaDescriptor instead')
const RimmMeta$json = {
  '1': 'RimmMeta',
  '2': [
    {'1': 'operator', '3': 1, '4': 1, '5': 9, '10': 'operator'},
    {'1': 'validity_date', '3': 2, '4': 1, '5': 9, '10': 'validityDate'},
  ],
};

/// Descriptor for `RimmMeta`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rimmMetaDescriptor = $convert.base64Decode(
    'CghSaW1tTWV0YRIaCghvcGVyYXRvchgBIAEoCVIIb3BlcmF0b3ISIwoNdmFsaWRpdHlfZGF0ZR'
    'gCIAEoCVIMdmFsaWRpdHlEYXRl');

@$core.Deprecated('Use rimmSearchResponseDescriptor instead')
const RimmSearchResponse$json = {
  '1': 'RimmSearchResponse',
  '2': [
    {'1': 'result_list', '3': 1, '4': 3, '5': 9, '10': 'resultList'},
    {'1': 'total_count', '3': 2, '4': 1, '5': 5, '10': 'totalCount'},
    {'1': 'error', '3': 3, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `RimmSearchResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rimmSearchResponseDescriptor = $convert.base64Decode(
    'ChJSaW1tU2VhcmNoUmVzcG9uc2USHwoLcmVzdWx0X2xpc3QYASADKAlSCnJlc3VsdExpc3QSHw'
    'oLdG90YWxfY291bnQYAiABKAVSCnRvdGFsQ291bnQSFAoFZXJyb3IYAyABKAlSBWVycm9y');

@$core.Deprecated('Use submitSignedDeclarationRequestDescriptor instead')
const SubmitSignedDeclarationRequest$json = {
  '1': 'SubmitSignedDeclarationRequest',
  '2': [
    {'1': 'json_payload', '3': 1, '4': 1, '5': 9, '10': 'jsonPayload'},
    {'1': 'p12_buffer', '3': 2, '4': 1, '5': 12, '10': 'p12Buffer'},
    {'1': 'p12_pin', '3': 3, '4': 1, '5': 9, '10': 'p12Pin'},
    {
      '1': 'auth',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.aduanext.hacienda.AuthenticateRequest',
      '10': 'auth'
    },
    {'1': 'validate_only', '3': 5, '4': 1, '5': 8, '10': 'validateOnly'},
  ],
};

/// Descriptor for `SubmitSignedDeclarationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List submitSignedDeclarationRequestDescriptor = $convert.base64Decode(
    'Ch5TdWJtaXRTaWduZWREZWNsYXJhdGlvblJlcXVlc3QSIQoManNvbl9wYXlsb2FkGAEgASgJUg'
    'tqc29uUGF5bG9hZBIdCgpwMTJfYnVmZmVyGAIgASgMUglwMTJCdWZmZXISFwoHcDEyX3BpbhgD'
    'IAEoCVIGcDEyUGluEjoKBGF1dGgYBCABKAsyJi5hZHVhbmV4dC5oYWNpZW5kYS5BdXRoZW50aW'
    'NhdGVSZXF1ZXN0UgRhdXRoEiMKDXZhbGlkYXRlX29ubHkYBSABKAhSDHZhbGlkYXRlT25seQ==');

@$core.Deprecated('Use submitSignedDeclarationResponseDescriptor instead')
const SubmitSignedDeclarationResponse$json = {
  '1': 'SubmitSignedDeclarationResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'status', '3': 2, '4': 1, '5': 9, '10': 'status'},
    {
      '1': 'customs_registration_number',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'customsRegistrationNumber'
    },
    {
      '1': 'assessment_serial',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'assessmentSerial'
    },
    {
      '1': 'assessment_number',
      '3': 5,
      '4': 1,
      '5': 5,
      '10': 'assessmentNumber'
    },
    {'1': 'assessment_date', '3': 6, '4': 1, '5': 9, '10': 'assessmentDate'},
    {'1': 'json_response', '3': 7, '4': 1, '5': 9, '10': 'jsonResponse'},
    {'1': 'error', '3': 8, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `SubmitSignedDeclarationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List submitSignedDeclarationResponseDescriptor = $convert.base64Decode(
    'Ch9TdWJtaXRTaWduZWREZWNsYXJhdGlvblJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2'
    'Nlc3MSFgoGc3RhdHVzGAIgASgJUgZzdGF0dXMSPgobY3VzdG9tc19yZWdpc3RyYXRpb25fbnVt'
    'YmVyGAMgASgJUhljdXN0b21zUmVnaXN0cmF0aW9uTnVtYmVyEisKEWFzc2Vzc21lbnRfc2VyaW'
    'FsGAQgASgJUhBhc3Nlc3NtZW50U2VyaWFsEisKEWFzc2Vzc21lbnRfbnVtYmVyGAUgASgFUhBh'
    'c3Nlc3NtZW50TnVtYmVyEicKD2Fzc2Vzc21lbnRfZGF0ZRgGIAEoCVIOYXNzZXNzbWVudERhdG'
    'USIwoNanNvbl9yZXNwb25zZRgHIAEoCVIManNvblJlc3BvbnNlEhQKBWVycm9yGAggASgJUgVl'
    'cnJvcg==');
