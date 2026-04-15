// Package pkcs11wrap is a thin convenience layer over github.com/miekg/pkcs11
// that:
//
//   - Loads + initializes a module exactly once per session and tears it
//     down deterministically on Close.
//   - Marshals slot / token info into the protocol structs without leaking
//     the underlying CK_* types into the command handlers.
//   - Owns PIN lifetime: callers pass a string, the wrapper converts to
//     []byte and overwrites the bytes with zeros immediately after the
//     PKCS#11 C_Login call returns (success or failure).
//
// This package does not log anything. It returns errors that the command
// handlers translate into protocol error codes.
package pkcs11wrap

import (
	"crypto/x509"
	"encoding/pem"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/miekg/pkcs11"
	"github.com/vertivolatam/aduanext/pkcs11-helper/internal/protocol"
)

// Session bundles a loaded module + the slot enumeration. Callers Open it,
// use it, and Close it. Sessions are intentionally short-lived: one per
// helper request. This matches the spike's "no shared state across PIN
// boundaries" decision.
type Session struct {
	ctx        *pkcs11.Ctx
	modulePath string
}

// Open dlopens the module and runs C_Initialize. The caller MUST call
// Close, ideally in a defer.
func Open(modulePath string) (*Session, error) {
	if modulePath == "" {
		return nil, errors.New("module path is empty")
	}
	ctx := pkcs11.New(modulePath)
	if ctx == nil {
		return nil, fmt.Errorf("failed to load PKCS#11 module %q (dlopen returned nil)", modulePath)
	}
	if err := ctx.Initialize(); err != nil {
		// CKR_CRYPTOKI_ALREADY_INITIALIZED is benign for our purposes;
		// some middlewares Initialize themselves on dlopen.
		if !errors.Is(err, pkcs11.Error(pkcs11.CKR_CRYPTOKI_ALREADY_INITIALIZED)) {
			ctx.Destroy()
			return nil, fmt.Errorf("C_Initialize: %w", err)
		}
	}
	return &Session{ctx: ctx, modulePath: modulePath}, nil
}

// Close finalizes the module. Safe to call multiple times.
func (s *Session) Close() {
	if s == nil || s.ctx == nil {
		return
	}
	// We deliberately ignore Finalize errors — there is nothing useful
	// to do with them at process-shutdown time.
	_ = s.ctx.Finalize()
	s.ctx.Destroy()
	s.ctx = nil
}

// EnumerateSlots returns one [protocol.TokenSlot] per slot with a token
// present. Slots without a token are skipped (per the spike — the UI does
// not need to advertise empty readers).
func (s *Session) EnumerateSlots() ([]protocol.TokenSlot, error) {
	slots, err := s.ctx.GetSlotList(true /* tokenPresent */)
	if err != nil {
		return nil, fmt.Errorf("C_GetSlotList: %w", err)
	}
	out := make([]protocol.TokenSlot, 0, len(slots))
	for _, slotID := range slots {
		ti, err := s.ctx.GetTokenInfo(slotID)
		if err != nil {
			// Skip unreadable slots rather than failing the whole enum.
			continue
		}
		entry := protocol.TokenSlot{
			SlotID:       uint(slotID),
			TokenLabel:   strings.TrimSpace(ti.Label),
			TokenSerial:  strings.TrimSpace(ti.SerialNumber),
			Manufacturer: strings.TrimSpace(ti.ManufacturerID),
			Model:        strings.TrimSpace(ti.Model),
		}
		// Best-effort: open a public session and see if there is a cert.
		if cert, ok := s.tryReadFirstCert(slotID); ok {
			entry.HasCert = true
			entry.CertCommonName = cert.Subject.CommonName
			entry.CertSubject = cert.Subject.String()
			entry.CertIssuer = cert.Issuer.String()
			entry.CertNotBefore = cert.NotBefore.UTC().Format(time.RFC3339)
			entry.CertNotAfter = cert.NotAfter.UTC().Format(time.RFC3339)
		}
		out = append(out, entry)
	}
	return out, nil
}

// tryReadFirstCert opens a read-only session, finds the first
// CKO_CERTIFICATE object, and decodes it. Returns (nil, false) on any
// problem — this is best-effort metadata for the slot picker.
func (s *Session) tryReadFirstCert(slotID uint) (*x509.Certificate, bool) {
	sess, err := s.ctx.OpenSession(slotID, pkcs11.CKF_SERIAL_SESSION)
	if err != nil {
		return nil, false
	}
	defer s.ctx.CloseSession(sess)

	template := []*pkcs11.Attribute{
		pkcs11.NewAttribute(pkcs11.CKA_CLASS, pkcs11.CKO_CERTIFICATE),
	}
	if err := s.ctx.FindObjectsInit(sess, template); err != nil {
		return nil, false
	}
	objs, _, err := s.ctx.FindObjects(sess, 1)
	_ = s.ctx.FindObjectsFinal(sess)
	if err != nil || len(objs) == 0 {
		return nil, false
	}
	attrs, err := s.ctx.GetAttributeValue(sess, objs[0], []*pkcs11.Attribute{
		pkcs11.NewAttribute(pkcs11.CKA_VALUE, nil),
	})
	if err != nil || len(attrs) == 0 || len(attrs[0].Value) == 0 {
		return nil, false
	}
	cert, err := x509.ParseCertificate(attrs[0].Value)
	if err != nil {
		return nil, false
	}
	return cert, true
}

// SignContext bundles everything needed for a single sign operation.
type SignContext struct {
	SlotID    uint
	PIN       string
	Data      []byte
	Mechanism uint
}

// SignResultRaw is the wrap-level (pre-protocol) sign result. The command
// handler converts to protocol.SignResult.
type SignResultRaw struct {
	Signature   []byte
	SignerCert  *x509.Certificate
	SignerCertDER []byte
	TokenSerial string
}

// Sign opens a session, logs in with the provided PIN, locates the first
// CKO_PRIVATE_KEY + matching CKO_CERTIFICATE, signs `data`, and returns
// the raw signature plus the signer cert (so the caller can record the
// CN in the audit trail).
//
// PIN handling: the input string is COPIED into a []byte that is
// overwritten with zeros before this function returns, regardless of
// success or failure path.
func (s *Session) Sign(in SignContext) (*SignResultRaw, error) {
	pinBytes := []byte(in.PIN)
	defer zeroize(pinBytes)

	// Verify token presence + grab the serial up front so the caller can
	// audit it even on later failures.
	ti, err := s.ctx.GetTokenInfo(in.SlotID)
	if err != nil {
		return nil, errTokenNotPresent(err)
	}
	tokenSerial := strings.TrimSpace(ti.SerialNumber)

	sess, err := s.ctx.OpenSession(in.SlotID, pkcs11.CKF_SERIAL_SESSION|pkcs11.CKF_RW_SESSION)
	if err != nil {
		return nil, fmt.Errorf("C_OpenSession: %w", err)
	}
	defer s.ctx.CloseSession(sess)

	if err := s.ctx.Login(sess, pkcs11.CKU_USER, string(pinBytes)); err != nil {
		return nil, classifyLoginError(err)
	}
	defer s.ctx.Logout(sess)

	priv, err := s.findFirstObject(sess, pkcs11.CKO_PRIVATE_KEY)
	if err != nil {
		return nil, err
	}
	if priv == 0 {
		return nil, errNoPrivateKey()
	}

	cert, certDER, err := s.findFirstCertificate(sess)
	if err != nil {
		return nil, err
	}

	mech := []*pkcs11.Mechanism{pkcs11.NewMechanism(in.Mechanism, nil)}
	if err := s.ctx.SignInit(sess, mech, priv); err != nil {
		return nil, classifySignError(err)
	}
	sig, err := s.ctx.Sign(sess, in.Data)
	if err != nil {
		return nil, classifySignError(err)
	}

	out := &SignResultRaw{
		Signature:     sig,
		SignerCert:    cert,
		SignerCertDER: certDER,
		TokenSerial:   tokenSerial,
	}
	return out, nil
}

func (s *Session) findFirstObject(sess pkcs11.SessionHandle, class uint) (pkcs11.ObjectHandle, error) {
	template := []*pkcs11.Attribute{
		pkcs11.NewAttribute(pkcs11.CKA_CLASS, class),
	}
	if err := s.ctx.FindObjectsInit(sess, template); err != nil {
		return 0, fmt.Errorf("C_FindObjectsInit: %w", err)
	}
	objs, _, err := s.ctx.FindObjects(sess, 1)
	_ = s.ctx.FindObjectsFinal(sess)
	if err != nil {
		return 0, fmt.Errorf("C_FindObjects: %w", err)
	}
	if len(objs) == 0 {
		return 0, nil
	}
	return objs[0], nil
}

func (s *Session) findFirstCertificate(sess pkcs11.SessionHandle) (*x509.Certificate, []byte, error) {
	obj, err := s.findFirstObject(sess, pkcs11.CKO_CERTIFICATE)
	if err != nil {
		return nil, nil, err
	}
	if obj == 0 {
		return nil, nil, errNoCertificate()
	}
	attrs, err := s.ctx.GetAttributeValue(sess, obj, []*pkcs11.Attribute{
		pkcs11.NewAttribute(pkcs11.CKA_VALUE, nil),
	})
	if err != nil || len(attrs) == 0 || len(attrs[0].Value) == 0 {
		return nil, nil, errNoCertificate()
	}
	cert, err := x509.ParseCertificate(attrs[0].Value)
	if err != nil {
		return nil, attrs[0].Value, fmt.Errorf("parse cert: %w", err)
	}
	return cert, attrs[0].Value, nil
}

// PEMEncodeCert returns a PEM CERTIFICATE block for the provided DER bytes.
func PEMEncodeCert(der []byte) string {
	return string(pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: der}))
}

func zeroize(b []byte) {
	for i := range b {
		b[i] = 0
	}
}
