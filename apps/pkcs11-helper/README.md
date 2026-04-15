# aduanext-pkcs11-helper

Native subprocess that bridges AduaNext (Dart) to PKCS#11 hardware tokens
— specifically Costa Rican BCCR Firma Digital USB smart cards (Gemalto
IDPrime MD 830 / MD 840 and equivalents).

This binary is the implementation half of [SPIKE 005][spike] and the
deliverable for [VRTV-69][issue]. It is consumed by
`SubprocessPkcs11SigningAdapter` (Dart, [VRTV-70][port]); it has no other
callers.

[spike]: ../../spikes/spike-005-pkcs11-tokens.md
[issue]: https://linear.app/vertivolatam/issue/VRTV-69
[port]: https://linear.app/vertivolatam/issue/VRTV-70

## Architecture

- Pure Go, statically linked, ~3 MB per `GOOS/GOARCH` pair.
- Wraps `github.com/miekg/pkcs11` — a stable, widely deployed binding
  used by `scdaemon`, `step-ca`, and Costa Rican electronic invoicing
  clients (ATV Firmador, Fermat).
- **No business logic.** The helper marshals stdio JSON into
  `C_Initialize` / `C_FindObjects` / `C_Sign` and back. WHEN to sign,
  WHICH cert to pick, and WHAT to do with the signature live in the
  Dart use-case layer.
- **No PIN persistence.** Every `sign` request carries its own PIN. The
  PIN is converted to bytes, passed to `C_Login`, and overwritten with
  zeros immediately afterwards. The PIN is never logged to stderr or
  echoed in any response, including error frames — this is enforced
  by a unit test (`TestServe_PinNeverInOutput`).

## Stdio protocol

Newline-delimited JSON. One request per line on stdin, one response per
line on stdout.

### Request envelope

```json
{"id": "<opaque correlation id>", "command": "<cmd>", "params": { ... }}
```

### Response envelope

Success:

```json
{"id": "<echo>", "ok": true, "result": { ... }}
```

Failure:

```json
{"id": "<echo>", "ok": false, "error": {"code": "<CODE>", "message": "<human-readable>"}}
```

### Commands

| command          | params                                                                  | result                                                            |
|------------------|-------------------------------------------------------------------------|-------------------------------------------------------------------|
| `version`        | _(none)_                                                                | `{ version, gitSha, buildDate, goVersion }`                       |
| `enumerateSlots` | `{ module: string }`                                                    | `{ slots: TokenSlot[] }`                                          |
| `sign`           | `{ module, slotId, pin, dataB64, mechanism }`                           | `{ signatureB64, signerCommonName, signerCertB64, signedAt, tokenSerial }` |
| `verify`         | `{ certPem, dataB64, signatureB64, mechanism }`                         | `{ valid: bool }`                                                 |

`module` is the absolute path to the PKCS#11 shared library. The helper
is intentionally module-agnostic. Common values:

- BCCR / Gemalto on Linux: `/usr/lib/x64-athena/ASEP11.so`
- OpenSC: `/usr/lib/x86_64-linux-gnu/opensc-pkcs11.so`
- SoftHSM2 (testing): `/usr/lib/softhsm/libsofthsm2.so`

### Supported mechanisms

- `CKM_SHA256_RSA_PKCS` — RSA PKCS#1 v1.5 with SHA-256 (BCCR XAdES-BES default)
- `CKM_SHA256_RSA_PKCS_PSS` — RSA-PSS with SHA-256
- `CKM_RSA_PKCS` — raw PKCS#1 v1.5; caller pre-hashes (XAdES SignedInfo case)

### Error codes

| code                     | meaning                                                            |
|--------------------------|--------------------------------------------------------------------|
| `INVALID_REQUEST`        | request could not be parsed or required fields missing             |
| `UNKNOWN_COMMAND`        | command name not recognised                                        |
| `MODULE_LOAD`            | dlopen of the PKCS#11 module failed or `C_Initialize` failed       |
| `TOKEN_NOT_PRESENT`      | no token in the requested slot                                     |
| `INVALID_PIN`            | wrong user PIN                                                     |
| `PIN_LOCKED`             | PIN locked after too many wrong attempts; SO PIN required          |
| `NO_CERTIFICATE`         | token does not expose a CKO_CERTIFICATE                            |
| `NO_PRIVATE_KEY`         | token does not expose a CKO_PRIVATE_KEY                            |
| `UNSUPPORTED_MECHANISM`  | requested mechanism not implemented or not supported by the token  |
| `SIGN_FAILED`            | other PKCS#11 sign failure; message carries the raw `CKR_*`        |
| `VERIFY_FAILED`          | RSA verify returned not-equal                                      |
| `INTERNAL`               | unexpected helper-side error                                       |

## Building

```bash
cd apps/pkcs11-helper
go build ./cmd/pkcs11-helper
./pkcs11-helper --version
```

To embed git SHA + build date:

```bash
go build \
  -ldflags="-s -w \
    -X github.com/vertivolatam/aduanext/pkcs11-helper/internal/commands.Version=$(git describe --tags --always) \
    -X github.com/vertivolatam/aduanext/pkcs11-helper/internal/commands.GitSHA=$(git rev-parse --short HEAD) \
    -X github.com/vertivolatam/aduanext/pkcs11-helper/internal/commands.BuildDate=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  ./cmd/pkcs11-helper
```

### Cross-compile targets (deferred)

The full matrix (`linux-amd64`, `linux-arm64`, `darwin-amd64`,
`darwin-arm64`, `windows-amd64`) plus binary signing (Authenticode,
notarisation) and Harbor / GitHub Releases distribution is tracked in a
follow-up issue (VRTV-58 release pipeline). For VRTV-69 we build the
runner-native binary in CI and verify it works.

## Testing

### Pure unit tests (always run)

```bash
go vet ./...
go test ./... -race
```

These cover the protocol marshaller and stdio dispatcher. They do NOT
require any PKCS#11 module.

### SoftHSM2 integration tests (CI + opt-in locally)

The `test/softhsm_smoke_test.go` suite is gated on these env vars:

| var                  | meaning                                            |
|----------------------|----------------------------------------------------|
| `SOFTHSM2_MODULE`    | path to `libsofthsm2.so`                           |
| `SOFTHSM2_SLOT_ID`   | numeric slot id created by the fixture             |
| `SOFTHSM2_USER_PIN`  | user PIN (default `1234` if unset)                 |

If `SOFTHSM2_MODULE` is unset the suite is skipped — `go test ./...`
still passes locally. CI sets all three after `apt install softhsm2 opensc`.
See `.github/workflows/pkcs11-ci.yml`.

To run locally:

```bash
sudo apt-get install -y softhsm2 opensc
mkdir -p /tmp/softhsm2-tokens
cat > /tmp/softhsm2.conf <<'EOF'
directories.tokendir = /tmp/softhsm2-tokens
objectstore.backend = file
log.level = ERROR
EOF
export SOFTHSM2_CONF=/tmp/softhsm2.conf
softhsm2-util --init-token --free --label aduanext-test \
  --so-pin 1234 --pin 1234

# Generate a key + cert in the token (see ci script for details)
# ...

export SOFTHSM2_MODULE=/usr/lib/softhsm/libsofthsm2.so
export SOFTHSM2_SLOT_ID=$(softhsm2-util --show-slots | grep -A1 'aduanext-test' | grep 'Slot' | awk '{print $2}')
go test ./test/...
```

## Security notes

- **PIN scoping:** per-call only. The helper does not cache, log, or
  display the PIN under any circumstance. A PIN sent in a malformed
  request that triggers an error frame is replaced with the empty
  string before error propagation (regression test:
  `TestServe_PinNeverInOutput`).
- **Module loading:** the helper dlopens whatever `module` path the
  caller passes. The Dart adapter is expected to validate this path
  against a configured allow-list before invoking the helper. The
  helper itself trusts the caller because the alternative — hardcoding
  middleware paths — would couple it to BCCR specifics.
- **Process isolation:** a bad PIN, disconnected token, or buggy
  middleware crashes only the helper process. The Dart VM is
  unaffected because all communication goes through pipes.

## Out of scope (tracked separately)

- Cross-compile matrix + binary distribution: VRTV-58
- BCCR token-specific quirks (middleware libs like `libcoolkeypk11.so`):
  caller passes the right `module` path
- Browser-side Flutter Web integration (Bit4id or Chrome extension):
  separate VRTV-56-web issue
- Real BCCR hardware testing: manual QA, requires physical device
