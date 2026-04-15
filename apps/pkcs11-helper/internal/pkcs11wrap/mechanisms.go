package pkcs11wrap

import (
	"fmt"

	"github.com/miekg/pkcs11"
)

// MechanismFromString resolves a string token (as it appears on the
// stdio protocol) into the PKCS#11 mechanism constant. The supported
// set is intentionally small — XAdES-BES and XAdES-EPES (Costa Rica
// BCCR) only require RSA-PKCS1 with SHA-256 and RSA-PSS with SHA-256.
//
// Adding more mechanisms is a one-line change; gate it on a real-world
// need, not on speculation.
func MechanismFromString(name string) (uint, error) {
	switch name {
	case "CKM_SHA256_RSA_PKCS":
		return pkcs11.CKM_SHA256_RSA_PKCS, nil
	case "CKM_SHA256_RSA_PKCS_PSS":
		return pkcs11.CKM_SHA256_RSA_PKCS_PSS, nil
	case "CKM_RSA_PKCS":
		// Raw RSA PKCS — caller hashes the data first. Useful for the
		// XAdES SignedInfo case where the digest is precomputed.
		return pkcs11.CKM_RSA_PKCS, nil
	default:
		return 0, fmt.Errorf("unsupported mechanism %q", name)
	}
}
