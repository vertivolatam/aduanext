// Command pkcs11-helper is the AduaNext PKCS#11 stdio bridge.
//
// It accepts newline-delimited JSON requests on stdin and emits
// newline-delimited JSON responses on stdout. The full protocol is
// defined in `internal/protocol`. The Dart adapter that drives this
// binary lives at
// `libs/adapters/lib/src/signing/subprocess_pkcs11_signing_adapter.dart`.
//
// This binary contains NO business logic — it is a thin marshaller
// over `github.com/miekg/pkcs11`. All decisions about WHEN to sign,
// WHICH certificate to use, and WHAT to do with the signature live in
// the Dart use-case layer.
package main

import (
	"bufio"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"runtime"

	"github.com/vertivolatam/aduanext/pkcs11-helper/internal/commands"
	"github.com/vertivolatam/aduanext/pkcs11-helper/internal/protocol"
)

func main() {
	versionFlag := flag.Bool("version", false, "print version + git SHA + Go runtime and exit")
	flag.Parse()

	if *versionFlag {
		fmt.Printf("aduanext-pkcs11-helper %s (commit %s, built %s, %s)\n",
			commands.Version, commands.GitSHA, commands.BuildDate, runtime.Version())
		return
	}

	if err := serve(os.Stdin, os.Stdout); err != nil {
		// Anything that escapes serve() is fatal — usually stdio gone.
		// We do NOT log to stderr because stderr is captured by the
		// parent and there is nothing useful to print without risking
		// PIN leakage from a malformed request that included one.
		os.Exit(1)
	}
}

// serve reads requests line-by-line and dispatches each to its handler.
// Returns when stdin is closed (EOF) or an unrecoverable I/O error
// occurs. Per-request errors are returned as protocol error frames, NOT
// surfaced here.
func serve(in io.Reader, out io.Writer) error {
	// Generous buffer — DUA payloads can be tens of KB once base64 +
	// JSON-escaped. Cap at 16 MB to defend against runaway input.
	scanner := bufio.NewScanner(in)
	scanner.Buffer(make([]byte, 64*1024), 16*1024*1024)

	enc := json.NewEncoder(out)
	enc.SetEscapeHTML(false)

	for scanner.Scan() {
		line := scanner.Bytes()
		if len(line) == 0 {
			continue
		}
		resp := dispatch(line)
		if err := enc.Encode(resp); err != nil {
			return err
		}
	}
	if err := scanner.Err(); err != nil && !errors.Is(err, io.EOF) {
		return err
	}
	return nil
}

// dispatch parses a single request line and routes it to the matching
// handler. Any error during parse / dispatch becomes a protocol error
// frame so the caller can correlate with the request id (when present).
func dispatch(line []byte) protocol.Response {
	var req protocol.Request
	if err := json.Unmarshal(line, &req); err != nil {
		return protocol.Response{
			OK: false,
			Error: &protocol.ErrorPayload{
				Code:    protocol.ErrInvalidRequest,
				Message: "could not parse request: " + err.Error(),
			},
		}
	}

	var (
		result any
		errPL  *protocol.ErrorPayload
	)
	switch req.Command {
	case protocol.CmdEnumerateSlots:
		result, errPL = commands.HandleEnumerate(req.Params)
	case protocol.CmdSign:
		result, errPL = commands.HandleSign(req.Params)
	case protocol.CmdVerify:
		result, errPL = commands.HandleVerify(req.Params)
	case protocol.CmdVersion:
		result, errPL = commands.HandleVersion()
	default:
		errPL = &protocol.ErrorPayload{
			Code:    protocol.ErrUnknownCommand,
			Message: fmt.Sprintf("unknown command %q", req.Command),
		}
	}

	resp := protocol.Response{ID: req.ID}
	if errPL != nil {
		resp.OK = false
		resp.Error = errPL
		return resp
	}
	resp.OK = true
	if result != nil {
		bs, err := json.Marshal(result)
		if err != nil {
			return protocol.Response{
				ID: req.ID,
				OK: false,
				Error: &protocol.ErrorPayload{
					Code:    protocol.ErrInternal,
					Message: "marshal result: " + err.Error(),
				},
			}
		}
		resp.Result = bs
	}
	return resp
}
