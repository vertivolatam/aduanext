# XAdES-EPES signature verification

AduaNext signs every DUA with a PKCS#12 certificate issued by the BCCR
chain (Ley 8454, CAUCA Art. 23). For a digital signature to be
*functionally equivalent* to a handwritten one, verification must be
cryptographically sound — not just structural.

This document covers the contract landed in [VRTV-58](https://linear.app/vertivolatam/issue/VRTV-58)
and the roadmap for the full XAdES-EPES pipeline in VRTV-58b.

## Contract

The `SigningPort` (in `libs/domain`) now exposes two methods:

```dart
Future<bool> verifySignature(String signedContent);
Future<VerificationResult> verifySignatureDetailed(String signedContent);
```

`VerificationResult` carries every intermediate check so the UI can
render a precise explanation:

| field | meaning |
|---|---|
| `valid` | `true` iff **all** of signature + chain + (required) OCSP are good |
| `structuralValid` | `<ds:Signature>` parses and looks well-formed |
| `signatureValid` | RSA signature over canonicalized `<ds:SignedInfo>` matches |
| `chainValid` | chain terminates at a trusted BCCR root; each non-root cert in validity window |
| `ocspStatus` | one of `good / revoked / unknown / unreachable / skipped` |
| `signerCommonName` | CN from the signing certificate |
| `verifiedAt` | server-side timestamp of the verification |
| `reason` | human-readable explanation when `valid=false` |
| `degraded` | **true** when the verifier could not run the full pipeline |

## Degraded mode

When `degraded=true`:

- `valid` is **always `false`** — callers MUST NOT treat the result as
  legally binding.
- UIs MUST surface a prominent warning explaining the gap.
- The audit payload carries `degraded: true` so compliance reviewers
  can reconstruct the verification environment later.

The current `HaciendaSigningAdapter` always returns `degraded=true`
because the sidecar's `VerifySignature` RPC is structural-only today.
The full pipeline lands with VRTV-58b (sidecar-side implementation).

## Full pipeline (VRTV-58b)

The production verifier will run, in order:

1. **Canonicalize** `<ds:SignedInfo>` per XML-DSig C14N 1.1
   (exclusive canonicalization for most signatures; inclusive for a
   legacy minority).
2. **Compute digest** using the algorithm declared in `<ds:DigestMethod>`
   (today always `http://www.w3.org/2001/04/xmlenc#sha256`) and
   compare to `<ds:DigestValue>`.
3. **Verify RSA signature** over the canonicalized SignedInfo using the
   embedded certificate's public key.
4. **Validate certificate chain** against
   `infrastructure/certs/bccr-roots.pem`. Reject if the chain doesn't
   terminate at a trusted root, or if any cert is outside its
   validity window.
5. **OCSP revocation check** for every non-root certificate using the
   responder URL declared in the AuthorityInfoAccess extension. Cache
   responses for `nextUpdate` (RFC 6960).

## OCSP configuration

```dart
SignatureVerificationConfig(
  requireOcsp: true,          // strict — fail on unreachable
  ocspCacheTtl: Duration(hours: 1),
  clockSkew: Duration(minutes: 5),
  trustedRootsPath: 'infrastructure/certs/bccr-roots.pem',
)
```

- **`requireOcsp: true`** (default for production) — OCSP unreachable
  → `ocspStatus: unreachable`, `valid=false`.
- **`requireOcsp: false`** (staging / dev) — OCSP unreachable →
  `ocspStatus: unreachable`, `valid=true` with a non-blocking warning
  surfaced in the UI.

## Costa Rica TSA gap

There is **no national Trusted Timestamp Authority** in Costa Rica
(2026-04). We use `<xades:SigningTime>` from the signer's clock and
compare against the certificate's validity window; we do NOT yet
anchor the timestamp to a TSA signature. Long-term archival
(XAdES-A / XAdES-X-L) will require a TSA and is deferred to a future
issue.

## Test fixtures

Test certs live in `libs/adapters/test/signing/fixtures/` (landing
with VRTV-58b — this PR uses the sidecar fakes introduced in VRTV-54).
The fixture suite will cover:

- valid signed XML from a fixture CA → `valid=true`
- tampered XML (one byte changed) → `signatureValid=false`
- expired certificate → `chainValid=false`
- OCSP returns revoked → `ocspStatus=revoked`
- untrusted root → `chainValid=false`
- OCSP unreachable + `requireOcsp=true` → `valid=false`
- OCSP unreachable + `requireOcsp=false` → `valid=true` with warning

## Roadmap

| sub-issue | scope |
|---|---|
| VRTV-58 (this) | contract + `VerificationResult` + degraded mode + trust bundle placeholder |
| VRTV-58b | full XAdES-EPES canonicalizer + RSA verifier + chain + OCSP in the hacienda-sidecar; real BCCR bundle |
| VRTV-58c (if needed) | XAdES-A archival + national TSA coordination |
