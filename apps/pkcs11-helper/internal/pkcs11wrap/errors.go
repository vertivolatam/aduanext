package pkcs11wrap

import (
	"errors"
	"fmt"

	"github.com/miekg/pkcs11"
)

// CodedError pairs a wrapper-level error with the protocol error code the
// command handler should report. Using a typed error keeps the handler
// thin: it switches on .Code, not on string matching.
type CodedError struct {
	Code    string
	Message string
}

func (e *CodedError) Error() string { return e.Message }

// Codes — duplicated as strings here so the wrap layer does not import
// the protocol package (which would create a cycle in larger
// refactors). Command handlers cast back to protocol.ErrorCode.
const (
	CodeTokenNotPresent      = "TOKEN_NOT_PRESENT"
	CodeInvalidPin           = "INVALID_PIN"
	CodePinLocked            = "PIN_LOCKED"
	CodeNoCertificate        = "NO_CERTIFICATE"
	CodeNoPrivateKey         = "NO_PRIVATE_KEY"
	CodeUnsupportedMechanism = "UNSUPPORTED_MECHANISM"
	CodeSignFailed           = "SIGN_FAILED"
)

func errTokenNotPresent(cause error) error {
	return &CodedError{Code: CodeTokenNotPresent, Message: fmt.Sprintf("token not present: %v", cause)}
}

func errNoCertificate() error {
	return &CodedError{Code: CodeNoCertificate, Message: "no CKO_CERTIFICATE object found on token"}
}

func errNoPrivateKey() error {
	return &CodedError{Code: CodeNoPrivateKey, Message: "no CKO_PRIVATE_KEY object found on token"}
}

// classifyLoginError maps the PKCS#11 return code from C_Login into one
// of our typed errors. Anything we do not recognise becomes a generic
// SIGN_FAILED so the caller can still distinguish "PIN problem" from
// "everything else".
func classifyLoginError(err error) error {
	var pkErr pkcs11.Error
	if errors.As(err, &pkErr) {
		switch uint(pkErr) {
		case pkcs11.CKR_PIN_INCORRECT, pkcs11.CKR_PIN_INVALID, pkcs11.CKR_PIN_LEN_RANGE:
			return &CodedError{Code: CodeInvalidPin, Message: "user PIN is incorrect"}
		case pkcs11.CKR_PIN_LOCKED, pkcs11.CKR_USER_PIN_NOT_INITIALIZED:
			return &CodedError{Code: CodePinLocked, Message: "user PIN is locked or uninitialized"}
		}
	}
	return &CodedError{Code: CodeSignFailed, Message: fmt.Sprintf("C_Login: %v", err)}
}

// classifySignError covers C_SignInit / C_Sign return codes. The notable
// case is CKR_MECHANISM_INVALID for tokens that do not implement the
// requested mechanism.
func classifySignError(err error) error {
	var pkErr pkcs11.Error
	if errors.As(err, &pkErr) {
		switch uint(pkErr) {
		case pkcs11.CKR_MECHANISM_INVALID, pkcs11.CKR_MECHANISM_PARAM_INVALID:
			return &CodedError{Code: CodeUnsupportedMechanism, Message: fmt.Sprintf("token does not support requested mechanism: %v", err)}
		}
	}
	return &CodedError{Code: CodeSignFailed, Message: fmt.Sprintf("sign: %v", err)}
}
