package commands

import (
	"runtime"

	"github.com/vertivolatam/aduanext/pkcs11-helper/internal/protocol"
)

// BuildInfo is populated at link time via -ldflags. The defaults below
// are used when the binary is built without the build script.
var (
	Version   = "dev"
	GitSHA    = "unknown"
	BuildDate = "unknown"
)

// HandleVersion is the stdio counterpart of the `--version` flag.
func HandleVersion() (any, *protocol.ErrorPayload) {
	return protocol.VersionResult{
		Version:   Version,
		GitSHA:    GitSHA,
		BuildDate: BuildDate,
		GoVersion: runtime.Version(),
	}, nil
}
