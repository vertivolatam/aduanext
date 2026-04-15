package commands

import (
	"crypto"
	"crypto/rsa"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"errors"
	"fmt"

	"github.com/vertivolatam/aduanext/pkcs11-helper/internal/protocol"
)

// HandleVerify processes [protocol.CmdVerify]. Verification is performed
// in pure Go (no PKCS#11 needed) — it is included here so tests and
// self-checks can roundtrip without mounting a token.
func HandleVerify(raw json.RawMessage) (any, *protocol.ErrorPayload) {
	var p protocol.VerifyParams
	if err := json.Unmarshal(raw, &p); err != nil {
		return nil, &protocol.ErrorPayload{Code: protocol.ErrInvalidRequest, Message: "params: " + err.Error()}
	}
	cert, err := parseCertPEM(p.CertPEM)
	if err != nil {
		return nil, &protocol.ErrorPayload{Code: protocol.ErrInvalidRequest, Message: err.Error()}
	}
	data, err := base64.StdEncoding.DecodeString(p.DataB64)
	if err != nil {
		return nil, &protocol.ErrorPayload{Code: protocol.ErrInvalidRequest, Message: "dataB64: " + err.Error()}
	}
	sig, err := base64.StdEncoding.DecodeString(p.SignatureB64)
	if err != nil {
		return nil, &protocol.ErrorPayload{Code: protocol.ErrInvalidRequest, Message: "signatureB64: " + err.Error()}
	}

	rsaPub, ok := cert.PublicKey.(*rsa.PublicKey)
	if !ok {
		return nil, &protocol.ErrorPayload{Code: protocol.ErrInvalidRequest, Message: "only RSA certificates are supported"}
	}

	switch p.Mechanism {
	case "CKM_SHA256_RSA_PKCS":
		hashed := sha256.Sum256(data)
		if err := rsa.VerifyPKCS1v15(rsaPub, crypto.SHA256, hashed[:], sig); err != nil {
			return nil, &protocol.ErrorPayload{Code: protocol.ErrVerifyFailed, Message: err.Error()}
		}
	case "CKM_RSA_PKCS":
		// Caller already hashed.
		if err := rsa.VerifyPKCS1v15(rsaPub, crypto.SHA256, data, sig); err != nil {
			return nil, &protocol.ErrorPayload{Code: protocol.ErrVerifyFailed, Message: err.Error()}
		}
	default:
		return nil, &protocol.ErrorPayload{Code: protocol.ErrUnsupportedMechanism, Message: "verify: unsupported mechanism " + p.Mechanism}
	}
	return protocol.VerifyResult{Valid: true}, nil
}

func parseCertPEM(s string) (*x509.Certificate, error) {
	block, _ := pem.Decode([]byte(s))
	if block == nil {
		return nil, errors.New("cert is not PEM-encoded")
	}
	cert, err := x509.ParseCertificate(block.Bytes)
	if err != nil {
		return nil, fmt.Errorf("parse cert: %w", err)
	}
	return cert, nil
}
