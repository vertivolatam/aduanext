// Package test contains integration tests against a real PKCS#11 module
// (SoftHSM2 in CI). They are skipped when the SOFTHSM2_MODULE env var
// is not set, which keeps `go test ./...` green on dev workstations
// without SoftHSM2 installed.
package test

import (
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"os"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/vertivolatam/aduanext/pkcs11-helper/internal/commands"
	"github.com/vertivolatam/aduanext/pkcs11-helper/internal/protocol"
)

// requireSoftHSM marks the test as skipped if the SOFTHSM2_MODULE env var
// (path to libsofthsm2.so) is not set. The CI workflow
// `.github/workflows/pkcs11-ci.yml` sets it after `apt install softhsm2`.
func requireSoftHSM(t *testing.T) (modulePath, pin string, slotID uint) {
	t.Helper()
	modulePath = os.Getenv("SOFTHSM2_MODULE")
	if modulePath == "" {
		t.Skip("SOFTHSM2_MODULE not set; skipping SoftHSM2 smoke test")
	}
	pin = os.Getenv("SOFTHSM2_USER_PIN")
	if pin == "" {
		pin = "1234"
	}
	// SoftHSM2 assigns slot IDs randomly. The CI script writes the chosen
	// slot to SOFTHSM2_SLOT_ID; tests that need it read from there.
	slotEnv := os.Getenv("SOFTHSM2_SLOT_ID")
	if slotEnv == "" {
		t.Skip("SOFTHSM2_SLOT_ID not set; skipping (CI fixture missing)")
	}
	var s uint
	for _, ch := range slotEnv {
		if ch < '0' || ch > '9' {
			t.Fatalf("SOFTHSM2_SLOT_ID is not a positive integer: %q", slotEnv)
		}
		s = s*10 + uint(ch-'0')
	}
	return modulePath, pin, s
}

func TestEnumerateSlots_SoftHSM(t *testing.T) {
	modulePath, _, slotID := requireSoftHSM(t)

	params, _ := json.Marshal(protocol.EnumerateParams{Module: modulePath})
	res, errPL := commands.HandleEnumerate(params)
	require.Nil(t, errPL, "enumerate failed: %+v", errPL)
	enum, ok := res.(protocol.EnumerateResult)
	require.True(t, ok)
	require.NotEmpty(t, enum.Slots, "SoftHSM2 reported no slots — fixture not initialized?")

	var found bool
	for _, s := range enum.Slots {
		if s.SlotID == slotID {
			found = true
			assert.NotEmpty(t, s.TokenLabel)
			assert.True(t, s.HasCert, "test fixture should have a cert provisioned")
			assert.NotEmpty(t, s.CertCommonName)
		}
	}
	assert.True(t, found, "SOFTHSM2_SLOT_ID %d not present in slot list", slotID)
}

func TestSignRoundtrip_SoftHSM(t *testing.T) {
	modulePath, pin, slotID := requireSoftHSM(t)
	const payload = "AduaNext PKCS#11 SoftHSM2 smoke test"

	signParams, _ := json.Marshal(protocol.SignParams{
		Module:    modulePath,
		SlotID:    slotID,
		PIN:       pin,
		DataB64:   base64.StdEncoding.EncodeToString([]byte(payload)),
		Mechanism: "CKM_SHA256_RSA_PKCS",
	})
	res, errPL := commands.HandleSign(signParams)
	require.Nil(t, errPL, "sign failed: %+v", errPL)
	sigRes, ok := res.(protocol.SignResult)
	require.True(t, ok)
	require.NotEmpty(t, sigRes.SignatureB64)
	require.NotEmpty(t, sigRes.SignerCertB64)
	require.NotEmpty(t, sigRes.TokenSerial)

	// Verify the signature using the cert returned from sign.
	certDER, err := base64.StdEncoding.DecodeString(sigRes.SignerCertB64)
	require.NoError(t, err)
	cert, err := x509.ParseCertificate(certDER)
	require.NoError(t, err)
	certPEM := string(pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: cert.Raw}))

	verifyParams, _ := json.Marshal(protocol.VerifyParams{
		CertPEM:      certPEM,
		DataB64:      base64.StdEncoding.EncodeToString([]byte(payload)),
		SignatureB64: sigRes.SignatureB64,
		Mechanism:    "CKM_SHA256_RSA_PKCS",
	})
	vRes, vErr := commands.HandleVerify(verifyParams)
	require.Nil(t, vErr, "verify failed: %+v", vErr)
	v, ok := vRes.(protocol.VerifyResult)
	require.True(t, ok)
	assert.True(t, v.Valid)
}

func TestSignWithBadPin_SoftHSM(t *testing.T) {
	modulePath, _, slotID := requireSoftHSM(t)
	signParams, _ := json.Marshal(protocol.SignParams{
		Module:    modulePath,
		SlotID:    slotID,
		PIN:       "definitely-wrong-pin-9999",
		DataB64:   base64.StdEncoding.EncodeToString([]byte("x")),
		Mechanism: "CKM_SHA256_RSA_PKCS",
	})
	res, errPL := commands.HandleSign(signParams)
	require.Nil(t, res)
	require.NotNil(t, errPL)
	// Either INVALID_PIN or PIN_LOCKED is acceptable depending on
	// how many wrong attempts the CI fixture has already absorbed.
	assert.Contains(t, []protocol.ErrorCode{protocol.ErrInvalidPin, protocol.ErrPinLocked}, errPL.Code)
	// And critically — the wrong PIN must not be echoed in the message.
	assert.False(t, strings.Contains(errPL.Message, "9999"),
		"error message should not echo the PIN: %q", errPL.Message)
}
