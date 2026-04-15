package protocol

import "encoding/json"

// Response is the envelope returned for every request. Exactly one of
// `Result` or `Error` is set.
type Response struct {
	ID     string          `json:"id"`
	OK     bool            `json:"ok"`
	Result json.RawMessage `json:"result,omitempty"`
	Error  *ErrorPayload   `json:"error,omitempty"`
}

// ErrorPayload is the structured error body. The `code` is a stable
// machine-readable enum the Dart side maps to typed exceptions; the
// `message` is human-readable English (the Dart side localizes).
type ErrorPayload struct {
	Code    ErrorCode `json:"code"`
	Message string    `json:"message"`
}

// ErrorCode enumerates the failure modes the helper can report. New
// codes MUST be added to the Dart adapter's exception map at the same
// time — see `Pkcs11Exception` in libs/domain.
type ErrorCode string

const (
	// ErrInvalidRequest the request could not be parsed or required
	// fields were missing.
	ErrInvalidRequest ErrorCode = "INVALID_REQUEST"

	// ErrUnknownCommand the command field was not recognised.
	ErrUnknownCommand ErrorCode = "UNKNOWN_COMMAND"

	// ErrModuleLoad the PKCS#11 module could not be dlopened.
	ErrModuleLoad ErrorCode = "MODULE_LOAD"

	// ErrTokenNotPresent no token in the requested slot, or the slot
	// does not exist.
	ErrTokenNotPresent ErrorCode = "TOKEN_NOT_PRESENT"

	// ErrInvalidPin the user PIN was incorrect.
	ErrInvalidPin ErrorCode = "INVALID_PIN"

	// ErrPinLocked the PIN is locked after too many failed attempts.
	// Recovery requires the SO PIN, which AduaNext never sees.
	ErrPinLocked ErrorCode = "PIN_LOCKED"

	// ErrNoCertificate no certificate object was found on the token in
	// the requested slot.
	ErrNoCertificate ErrorCode = "NO_CERTIFICATE"

	// ErrNoPrivateKey no private key object was found on the token.
	ErrNoPrivateKey ErrorCode = "NO_PRIVATE_KEY"

	// ErrUnsupportedMechanism the requested signing mechanism is not
	// supported by the token.
	ErrUnsupportedMechanism ErrorCode = "UNSUPPORTED_MECHANISM"

	// ErrSignFailed signing failed for a reason not covered above. The
	// `message` carries the underlying PKCS#11 error code.
	ErrSignFailed ErrorCode = "SIGN_FAILED"

	// ErrVerifyFailed verification failed because the signature did not
	// match the data + cert combination.
	ErrVerifyFailed ErrorCode = "VERIFY_FAILED"

	// ErrInternal an unexpected error inside the helper.
	ErrInternal ErrorCode = "INTERNAL"
)

// Result payload for [CmdEnumerateSlots]. `slots` is empty when the
// module loads but no tokens are present.
type EnumerateResult struct {
	Slots []TokenSlot `json:"slots"`
}

// TokenSlot is a single PKCS#11 slot with a token present. Field naming
// mirrors the Dart `TokenSlot` value object.
type TokenSlot struct {
	SlotID            uint   `json:"slotId"`
	TokenLabel        string `json:"tokenLabel"`
	TokenSerial       string `json:"tokenSerial"`
	Manufacturer      string `json:"manufacturer"`
	Model             string `json:"model"`
	HasCert           bool   `json:"hasCert"`
	CertCommonName    string `json:"certCommonName,omitempty"`
	CertNotBefore     string `json:"certNotBefore,omitempty"`
	CertNotAfter      string `json:"certNotAfter,omitempty"`
	CertSubject       string `json:"certSubject,omitempty"`
	CertIssuer        string `json:"certIssuer,omitempty"`
}

// Result payload for [CmdSign]. `signatureB64` is the raw signature
// bytes base64-encoded. The XAdES envelope is built by the Dart side.
type SignResult struct {
	SignatureB64    string `json:"signatureB64"`
	SignerCN        string `json:"signerCommonName"`
	SignerCertB64   string `json:"signerCertB64"`
	SignedAt        string `json:"signedAt"`
	TokenSerial     string `json:"tokenSerial"`
}

// Result payload for [CmdVerify].
type VerifyResult struct {
	Valid bool `json:"valid"`
}

// Result payload for [CmdVersion].
type VersionResult struct {
	Version   string `json:"version"`
	GitSHA    string `json:"gitSha"`
	BuildDate string `json:"buildDate"`
	GoVersion string `json:"goVersion"`
}
