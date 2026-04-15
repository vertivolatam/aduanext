package protocol

import (
	"encoding/json"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestRequestRoundtrip(t *testing.T) {
	bs := []byte(`{"id":"x","command":"sign","params":{"slotId":3}}`)
	var req Request
	require.NoError(t, json.Unmarshal(bs, &req))
	assert.Equal(t, "x", req.ID)
	assert.Equal(t, CmdSign, req.Command)
	assert.JSONEq(t, `{"slotId":3}`, string(req.Params))
}

func TestErrorFrameMarshal(t *testing.T) {
	resp := Response{
		ID: "y",
		OK: false,
		Error: &ErrorPayload{
			Code:    ErrInvalidPin,
			Message: "bad pin",
		},
	}
	bs, err := json.Marshal(resp)
	require.NoError(t, err)
	assert.JSONEq(t,
		`{"id":"y","ok":false,"error":{"code":"INVALID_PIN","message":"bad pin"}}`,
		string(bs))
}

func TestSuccessFrameMarshal(t *testing.T) {
	raw, _ := json.Marshal(VerifyResult{Valid: true})
	resp := Response{ID: "z", OK: true, Result: raw}
	bs, err := json.Marshal(resp)
	require.NoError(t, err)
	assert.JSONEq(t, `{"id":"z","ok":true,"result":{"valid":true}}`, string(bs))
}
