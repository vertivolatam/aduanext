/// Test helpers for Keycloak JWT tests — generate an RSA keypair in
/// memory, expose it both as PointyCastle objects (for signing) and as
/// a JWK-formatted Map (for feeding the [JwksCache]).
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart' as pc;

/// One RSA keypair plus its JWK projection.
class RsaTestKeypair {
  final pc.RSAPrivateKey privateKey;
  final pc.RSAPublicKey publicKey;
  final String kid;

  RsaTestKeypair({
    required this.privateKey,
    required this.publicKey,
    required this.kid,
  });

  /// Build the JSON Web Key (JWK) representation of the public key for
  /// the JWKS endpoint body.
  Map<String, dynamic> toPublicJwk() {
    return {
      'kty': 'RSA',
      'kid': kid,
      'use': 'sig',
      'alg': 'RS256',
      'n': _bigIntToBase64Url(publicKey.modulus!),
      'e': _bigIntToBase64Url(publicKey.exponent!),
    };
  }
}

/// Deterministic keygen for tests (fixed seed) so CI is reproducible.
/// Uses 2048-bit keys — smaller keys (1024) are faster but trigger
/// pointycastle's minimum-modulus guard in newer versions.
RsaTestKeypair generateRsaTestKeypair({
  String kid = 'test-key-1',
  int bitSize = 2048,
  int seed = 0xBADF00D,
}) {
  final rng = pc.FortunaRandom();
  final seedBytes = Uint8List(32);
  final rand = Random(seed);
  for (var i = 0; i < seedBytes.length; i++) {
    seedBytes[i] = rand.nextInt(256);
  }
  rng.seed(pc.KeyParameter(seedBytes));

  final params = pc.RSAKeyGeneratorParameters(
    BigInt.parse('65537'),
    bitSize,
    64,
  );
  final keygen = pc.RSAKeyGenerator()
    ..init(pc.ParametersWithRandom(params, rng));
  final pair = keygen.generateKeyPair();
  return RsaTestKeypair(
    privateKey: pair.privateKey,
    publicKey: pair.publicKey,
    kid: kid,
  );
}

/// Build the JWKS endpoint body for [keypairs].
String buildJwksBody(Iterable<RsaTestKeypair> keypairs) {
  return jsonEncode({
    'keys': [for (final kp in keypairs) kp.toPublicJwk()],
  });
}

String _bigIntToBase64Url(BigInt value) {
  final bytes = _bigIntToBytes(value);
  return base64Url.encode(bytes).replaceAll('=', '');
}

Uint8List _bigIntToBytes(BigInt value) {
  var v = value;
  final bytes = <int>[];
  while (v > BigInt.zero) {
    bytes.insert(0, (v & BigInt.from(0xff)).toInt());
    v = v >> 8;
  }
  // Strip leading zero if high bit set? JWK spec requires unsigned
  // big-endian with no leading zeros, but we never produce a sign bit here.
  return Uint8List.fromList(bytes);
}
