package main

import (
	"bytes"
	"encoding/json"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/vertivolatam/aduanext/pkcs11-helper/internal/protocol"
)

// Pure-Go tests for the stdio dispatcher: no PKCS#11 module is loaded,
// so these run on every CI runner without SoftHSM2.

func TestDispatch_UnknownCommand(t *testing.T) {
	req := protocol.Request{ID: "1", Command: "frobnicate"}
	bs, _ := json.Marshal(req)
	resp := dispatch(bs)
	require.False(t, resp.OK)
	require.NotNil(t, resp.Error)
	assert.Equal(t, "1", resp.ID)
	assert.Equal(t, protocol.ErrUnknownCommand, resp.Error.Code)
}

func TestDispatch_InvalidJSON(t *testing.T) {
	resp := dispatch([]byte("{not json"))
	require.False(t, resp.OK)
	require.NotNil(t, resp.Error)
	assert.Equal(t, protocol.ErrInvalidRequest, resp.Error.Code)
}

func TestDispatch_VersionCommand(t *testing.T) {
	req := protocol.Request{ID: "v", Command: protocol.CmdVersion}
	bs, _ := json.Marshal(req)
	resp := dispatch(bs)
	require.True(t, resp.OK, "expected OK but got error: %+v", resp.Error)
	require.NotNil(t, resp.Result)
	var v protocol.VersionResult
	require.NoError(t, json.Unmarshal(resp.Result, &v))
	assert.NotEmpty(t, v.GoVersion)
	assert.NotEmpty(t, v.Version)
}

func TestDispatch_EnumerateRequiresModule(t *testing.T) {
	req := protocol.Request{
		ID:      "e",
		Command: protocol.CmdEnumerateSlots,
		Params:  json.RawMessage(`{}`),
	}
	bs, _ := json.Marshal(req)
	resp := dispatch(bs)
	require.False(t, resp.OK)
	assert.Equal(t, protocol.ErrInvalidRequest, resp.Error.Code)
}

func TestDispatch_EnumerateBadModulePath(t *testing.T) {
	req := protocol.Request{
		ID:      "e2",
		Command: protocol.CmdEnumerateSlots,
		Params:  json.RawMessage(`{"module": "/nonexistent/path/to.so"}`),
	}
	bs, _ := json.Marshal(req)
	resp := dispatch(bs)
	require.False(t, resp.OK)
	assert.Equal(t, protocol.ErrModuleLoad, resp.Error.Code)
}

func TestServe_MultipleRequestsRoundtrip(t *testing.T) {
	in := strings.NewReader(
		`{"id":"a","command":"version"}` + "\n" +
			`{"id":"b","command":"version"}` + "\n",
	)
	var out bytes.Buffer
	require.NoError(t, serve(in, &out))

	lines := strings.Split(strings.TrimSpace(out.String()), "\n")
	require.Len(t, lines, 2)
	for i, expectedID := range []string{"a", "b"} {
		var resp protocol.Response
		require.NoError(t, json.Unmarshal([]byte(lines[i]), &resp))
		assert.Equal(t, expectedID, resp.ID)
		assert.True(t, resp.OK)
	}
}

func TestServe_PinNeverInOutput(t *testing.T) {
	// Even on the bad-PIN error path the helper must NEVER echo the PIN
	// back. We build a request with an obviously-distinct PIN and assert
	// it does not appear in stdout (the failure path returns
	// MODULE_LOAD here because we have no real module, but that's fine
	// for the purpose of this regression).
	const sentinelPIN = "PIN_SENTINEL_5f8a91c3"
	req := protocol.Request{
		ID:      "s",
		Command: protocol.CmdSign,
		Params: json.RawMessage(
			`{"module":"/nonexistent.so","slotId":0,"pin":"` + sentinelPIN +
				`","dataB64":"SGVsbG8=","mechanism":"CKM_SHA256_RSA_PKCS"}`),
	}
	bs, _ := json.Marshal(req)
	in := bytes.NewReader(append(bs, '\n'))
	var out bytes.Buffer
	require.NoError(t, serve(in, &out))
	assert.NotContains(t, out.String(), sentinelPIN,
		"PIN must never appear in helper stdout, even in error frames")
}
