// Package protocol defines the newline-delimited JSON wire format used by the
// AduaNext PKCS#11 helper. Every line on stdin MUST be a single JSON object
// matching [Request]; every line on stdout MUST be a single JSON object
// matching [Response] in response.go.
//
// The helper is invoked as a subprocess by the Dart adapter
// (libs/adapters/lib/src/signing/subprocess_pkcs11_signing_adapter.dart) and
// is intentionally agnostic of any business logic — it only marshals
// PKCS#11 calls into / out of the host process.
package protocol

import "encoding/json"

// Command identifies the operation requested on the helper.
type Command string

const (
	// CmdEnumerateSlots lists every slot exposed by the configured PKCS#11
	// module that has a token present.
	CmdEnumerateSlots Command = "enumerateSlots"

	// CmdSign signs a payload using the private key associated with a
	// specific slot. The PIN is provided per-call and is zeroed
	// immediately after use.
	CmdSign Command = "sign"

	// CmdVerify verifies a signature against a payload using a provided
	// X.509 certificate (PEM). Used in tests and for self-checks.
	CmdVerify Command = "verify"

	// CmdVersion returns the helper version string. Identical information
	// is available via the `--version` flag but exposing it on the
	// stdio protocol lets the Dart adapter health-check a helper that
	// is already running.
	CmdVersion Command = "version"
)

// Request is the envelope for every helper request.
//
// Field naming is camelCase to match the rest of the codebase (Dart
// conventions). The `id` is opaque to the helper — it is echoed back so
// the caller can correlate request / response on a long-lived process.
type Request struct {
	ID      string          `json:"id"`
	Command Command         `json:"command"`
	Params  json.RawMessage `json:"params,omitempty"`
}

// EnumerateParams parameters for [CmdEnumerateSlots].
//
// `module` is the absolute path to the PKCS#11 shared library. The helper
// is intentionally module-agnostic: callers pass the right `.so` / `.dylib`
// / `.dll` for whichever middleware the user has installed (BCCR, OpenSC,
// SoftHSM2, etc.).
type EnumerateParams struct {
	Module string `json:"module"`
}

// SignParams parameters for [CmdSign].
//
// PIN is a string (not []byte) for JSON-friendliness. The helper converts
// to bytes, hands them to PKCS#11, and immediately zeroes the byte slice.
// The caller is responsible for keeping the PIN out of any logs on its
// side; the helper guarantees it is never written to its own stderr or
// stdout.
type SignParams struct {
	Module    string `json:"module"`
	SlotID    uint   `json:"slotId"`
	PIN       string `json:"pin"`
	DataB64   string `json:"dataB64"`
	Mechanism string `json:"mechanism"` // e.g. "CKM_SHA256_RSA_PKCS"
}

// VerifyParams parameters for [CmdVerify]. The certificate is a PEM-encoded
// X.509 string; data and signature are base64.
type VerifyParams struct {
	CertPEM      string `json:"certPem"`
	DataB64      string `json:"dataB64"`
	SignatureB64 string `json:"signatureB64"`
	Mechanism    string `json:"mechanism"`
}
