package commands

import (
	"encoding/json"

	"github.com/vertivolatam/aduanext/pkcs11-helper/internal/pkcs11wrap"
	"github.com/vertivolatam/aduanext/pkcs11-helper/internal/protocol"
)

// HandleEnumerate processes [protocol.CmdEnumerateSlots]. It opens a
// fresh session against the provided module, lists slots, and tears
// the session down before returning.
func HandleEnumerate(raw json.RawMessage) (any, *protocol.ErrorPayload) {
	var p protocol.EnumerateParams
	if err := json.Unmarshal(raw, &p); err != nil {
		return nil, &protocol.ErrorPayload{Code: protocol.ErrInvalidRequest, Message: "params: " + err.Error()}
	}
	if p.Module == "" {
		return nil, &protocol.ErrorPayload{Code: protocol.ErrInvalidRequest, Message: "params.module is required"}
	}
	sess, err := pkcs11wrap.Open(p.Module)
	if err != nil {
		return nil, &protocol.ErrorPayload{Code: protocol.ErrModuleLoad, Message: err.Error()}
	}
	defer sess.Close()

	slots, err := sess.EnumerateSlots()
	if err != nil {
		return nil, &protocol.ErrorPayload{Code: protocol.ErrInternal, Message: err.Error()}
	}
	return protocol.EnumerateResult{Slots: slots}, nil
}
