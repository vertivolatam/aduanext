/// Port: Digital Signing — abstracts document signing mechanisms.
///
/// Costa Rica uses XAdES-EPES with PKCS#12 certificates from BCCR.
/// Other countries may use different signing standards (CMS, PAdES, etc.).
library;

/// Result of a signing operation.
class SigningResult {
  final bool success;
  final String? signedContent;
  final String? signerCommonName;
  final String? errorMessage;

  const SigningResult({
    required this.success,
    this.signedContent,
    this.signerCommonName,
    this.errorMessage,
  });
}

/// Port: Digital Signing — country-agnostic signing interface.
abstract class SigningPort {
  /// Sign content with the configured digital certificate.
  Future<SigningResult> sign(String content);

  /// Sign content and return base64-encoded result.
  Future<SigningResult> signAndEncode(String content);

  /// Verify a signed document.
  Future<bool> verifySignature(String signedContent);
}
