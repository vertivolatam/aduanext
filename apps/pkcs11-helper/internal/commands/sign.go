package commands

import (
	"encoding/base64"
	"encoding/json"
	"errors"
	"time"

	"github.com/vertivolatam/aduanext/pkcs11-helper/internal/pkcs11wrap"
	"github.com/vertivolatam/aduanext/pkcs11-helper/internal/protocol"
)

// HandleSign processes [protocol.CmdSign]. The PIN is taken from the
// JSON params and forwarded to the wrap layer, which is responsible
// for zeroing it after the C_Login call.
func HandleSign(raw json.RawMessage) (any, *protocol.ErrorPayload) {
	var p protocol.SignParams
	if err := json.Unmarshal(raw, &p); err != nil {
		return nil, &protocol.ErrorPayload{Code: protocol.ErrInvalidRequest, Message: "params: " + err.Error()}
	}
	if p.Module == "" || p.Mechanism == "" || p.DataB64 == "" {
		return nil, &protocol.ErrorPayload{Code: protocol.ErrInvalidRequest, Message: "module, mechanism, and dataB64 are required"}
	}
	data, err := base64.StdEncoding.DecodeString(p.DataB64)
	if err != nil {
		return nil, &protocol.ErrorPayload{Code: protocol.ErrInvalidRequest, Message: "dataB64 is not valid base64: " + err.Error()}
	}
	mech, err := pkcs11wrap.MechanismFromString(p.Mechanism)
	if err != nil {
		return nil, &protocol.ErrorPayload{Code: protocol.ErrUnsupportedMechanism, Message: err.Error()}
	}

	sess, err := pkcs11wrap.Open(p.Module)
	if err != nil {
		return nil, &protocol.ErrorPayload{Code: protocol.ErrModuleLoad, Message: err.Error()}
	}
	defer sess.Close()

	out, err := sess.Sign(pkcs11wrap.SignContext{
		SlotID:    p.SlotID,
		PIN:       p.PIN,
		Data:      data,
		Mechanism: mech,
	})
	// Wipe local copy of the PIN immediately. The wrap-layer copy is
	// already zeroed at this point; this defends against the JSON
	// decoder's interned strings still being reachable.
	p.PIN = ""
	if err != nil {
		var coded *pkcs11wrap.CodedError
		if errors.As(err, &coded) {
			return nil, &protocol.ErrorPayload{Code: protocol.ErrorCode(coded.Code), Message: coded.Message}
		}
		return nil, &protocol.ErrorPayload{Code: protocol.ErrSignFailed, Message: err.Error()}
	}

	res := protocol.SignResult{
		SignatureB64:  base64.StdEncoding.EncodeToString(out.Signature),
		SignedAt:      time.Now().UTC().Format(time.RFC3339),
		TokenSerial:   out.TokenSerial,
		SignerCertB64: base64.StdEncoding.EncodeToString(out.SignerCertDER),
	}
	if out.SignerCert != nil {
		res.SignerCN = out.SignerCert.Subject.CommonName
	}
	return res, nil
}
