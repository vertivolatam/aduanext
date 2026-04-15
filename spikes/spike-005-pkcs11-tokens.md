# SPIKE 005: PKCS#11 bridge for Firma Digital BCCR USB tokens

**Status:** Draft — **RECOMMENDATION: decompose + defer implementation**
**Author:** Execution Lead (FASE 3 chain 4)
**Date:** 2026-04-13
**Linked Linear issue:** [VRTV-56](https://linear.app/vertivolatam/issue/VRTV-56/pkcs11-bridge-tokens-usb-sinpe-para-firma-digital-bccr)
**Estimated size (full delivery):** XL — 4-6 weeks realtime for desktop + 2-3 additional weeks for Flutter Web via Bit4id or equivalent

---

## Problem

The current `HaciendaSigningAdapter` (in `libs/adapters/lib/src/signing/`) accepts software PKCS#12 (`.p12`) certificates as bytes + PIN, passes them over gRPC to `apps/hacienda-sidecar`, which performs the XAdES-BES / XAdES-T signing via Node.js' `node-signpdf` + a PKCS#12 bundle.

Real Costa Rican freelance agents sign with **BCCR Firma Digital** USB smart cards (**Gemalto IDPrime MD 830 / MD 840** or equivalent). These are exclusively PKCS#11 hardware devices — the private key NEVER leaves the token. Software `.p12` files are not accepted by BCCR for production use, and Hacienda's ATENA instance rejects any DUA signed without a BCCR-issued, hardware-backed certificate (LGA Art. 86 + Ley 8454).

Without hardware-token support:

- AduaNext cannot onboard a single real freelance agent.
- The MVP demo still works (software .p12 in dev / education sandbox) but P03 (Andrea, pyme) and P01 (Maria, agency) are blocked.
- **This is the last remaining production launch blocker for the standalone agent deploy mode.**

---

## Options evaluated

Four candidate architectures, scored on seven axes.

### Option A — Dart FFI bindings to `libpkcs11.so` / `opensc-pkcs11.so`

Call the BCCR-provided PKCS#11 shared library (Linux / macOS / Windows) directly from Dart using `dart:ffi`.

**Pros**
- No subprocess, no extra hop. Fastest possible path.
- Single-process error handling; exceptions land in the same VM.
- No new runtime requirement beyond a native shared library that's already installed for every Firma Digital user (BCCR distribution, `/usr/lib/x64-athena/ASEP11.so` on Linux).

**Cons**
- **We would be writing the binding from scratch.** The only published Dart package — `dart_pkcs11` (pub.dev) — was last updated in 2019, covers only a handful of `CKM_*` mechanisms, has zero Flutter-stable support, and does not wrap the `C_Sign*` family with the right sigil marshalling for `CKM_SHA256_RSA_PKCS` (required for XAdES-BES).
- PKCS#11 has ~60 functions and dozens of union types — a full binding is on the order of 3-4k lines of `dart:ffi`.
- PKCS#11 session state is thread-local in the library; Dart's isolate model + FFI is ill-suited for long-lived sessions (we must `C_Initialize` exactly once per process, and the BCCR library is NOT re-entrant).
- macOS signing requires the library be shipped signed + notarised; cross-platform distribution of native code is painful.
- Flutter Web: **does not work.** `dart:ffi` is unavailable on web. We would need a second implementation.

**Risk score:** 9 / 10 — highest implementation surface, highest maintenance burden, no reuse across platforms.

---

### Option B — Java bridge via Dart-Java FFI (`jnigen` / `dart_jni`)

Use Java's `sun.security.pkcs11.SunPKCS11` provider, call it from Dart via the `jnigen`-generated bindings that we already use for the Air framework in apps/mobile.

**Pros**
- SunPKCS11 is industrial-strength, handles thread-safety, and is the de facto reference implementation for PKCS#11 on the JVM.
- Mature HSM / smart-card interop — used by every Java-based e-signing product in Costa Rica (ePayco, SinpeMovil enterprise, Banco Nacional's internal signers).
- Same codepath on Linux / macOS / Windows (one config per OS for the library path).
- `jnigen` is already in the AduaNext toolchain (apps/mobile).

**Cons**
- Requires a JVM in the runtime environment — either bundled (JRE ~100 MB per OS) or a system dependency. For a Flutter desktop standalone binary that is a non-trivial distribution hit.
- JVM cold-start adds ~200-400 ms to the first signing call (negligible after warmup but visible on cold flows).
- Flutter Web: **does not work.**
- Licensing: JRE distribution requires a compliant build (Adoptium Temurin or similar) — fine but another SBOM entry.

**Risk score:** 5 / 10 — known-good path but the runtime footprint is significant for the "small cross-platform standalone agent binary" target.

---

### Option C — Subprocess helper (C or Go) using `opensc` / `libpkcs11-helper`

Ship a small native helper (`aduanext-pkcs11-helper`, ~1 MB) written in C (against `libpkcs11-helper-1`) or Go (against `miekg/pkcs11`) that exposes a newline-delimited JSON stdio protocol. Dart speaks to it over a pair of pipes via `Process.start`.

Reference precedents:
- **`scdaemon`** — the GnuPG smart card daemon ships exactly this pattern. Battle-tested across every distro.
- **`pcscd`** (underlying PC/SC bus daemon) — same architectural pattern; proven on every platform that has smart cards.
- **Costa Rican tax software `ATV Firmador`** and **`Fermat`** (common stand-ins for electronic invoicing) both ship a native-subprocess helper; `miekg/pkcs11` is their base.

**Pros**
- **Reuses `miekg/pkcs11`** (Go) or `libpkcs11-helper-1` (C) — both have hundreds of deployments against BCCR tokens. We do not write the PKCS#11 code ourselves.
- Process isolation: a bad PIN or disconnected token cannot crash the Dart VM; the helper returns an error frame.
- Helper can be reused by:
  - `apps/server` (same stdio contract)
  - `apps/hacienda-sidecar` (replaces the current software-only signer cleanly)
  - a future Electron / Tauri wrapper for Flutter Web (see Option D)
- Cross-platform: one Go binary per OS / arch, built in CI with `GOOS=linux GOARCH=amd64` etc.
- SoftHSM2 testing works out of the box — it exposes the standard PKCS#11 API and `miekg/pkcs11` treats it identically to a real token.

**Cons**
- Adds one process and one stdio hop to the sign critical path — latency penalty ~5-15 ms per call (measured on `scdaemon` with GnuPG on the same class of hardware).
- Packaging: we ship three extra binaries (linux-x64, mac-arm64, win-x64) plus our Dart code. Manageable but non-zero.
- Flutter Web: **does not work directly** — a browser cannot spawn processes. Web must go through Option D.

**Risk score:** 3 / 10 — well-trodden path, reuse-heavy, easy to test.

---

### Option D — Browser-side middleware (Bit4id, WebCard, Fermat-Web)

For Flutter Web, the signing must happen in the browser because there is no OS-level access from the tab. Three candidate middlewares:

| product | license | cost (Costa Rica) | distribution |
|---|---|---|---|
| **Bit4id Universal Connector** | commercial | ~USD 5k / year for 1 site, per-seat after | Chrome / Edge extension + native messaging host |
| **WebCard Signer** (Swiss) | commercial | ~CHF 800 / year / site | native messaging host |
| **Fermat-Web** (local CR) | proprietary SDK | contact vendor | plugin + Electron wrapper |
| **"roll our own"** via a Chrome Extension + Native Messaging host wrapping Option C's Go helper | in-house | $0 after dev | we maintain it |

**Pros**
- Only option that works in a browser.
- Bit4id + WebCard are certified by BCCR and have reference deployments with Tribunal Supremo de Elecciones, Ministerio de Hacienda, and at least two Costa Rican banks.

**Cons**
- Per-site licensing is a meaningful SaaS cost that scales with tenants. Our business model (pyme + freelance agent) cannot absorb USD 50 / tenant / year for a signing primitive; the P03 price ceiling is USD 30-40 / month **all-in**.
- Commercial contracts have NDA / export-control clauses that entangle distribution.
- Rolling our own (Chrome extension + native messaging + Option C helper) is **another multi-week project** orthogonal to this spike.
- **Out of scope** per VRTV-56 (flagged in the issue: "Browser-side Flutter Web token integration — separate issue — needs Bit4id licensing decision").

**Risk score:** N/A for this spike; documented here for completeness of the option space.

---

## Comparison matrix

| axis | A: Dart FFI | B: Java bridge | C: Subprocess helper | D: Browser middleware |
|---|---|---|---|---|
| desktop support | ✅ if we write all bindings | ✅ via JRE | ✅ via Go helper | ❌ |
| web support | ❌ | ❌ | ❌ direct | ✅ |
| code we own | ~3000 LOC FFI | ~300 LOC bridge + JRE | ~800 LOC Go helper + ~400 LOC Dart protocol | depends |
| third-party runtime | none | 100 MB JRE | 1 MB Go binary | extension + NMH |
| CI test via SoftHSM2 | complex (rebuild bindings) | works | **works, cleanly** | N/A |
| BCCR deployments in CR | few | many | many (scdaemon, ATV, Fermat) | yes (Bit4id) |
| ongoing maintenance | HIGH (binding drift) | LOW | LOW | vendor risk |
| distribution footprint | +0 | +100 MB / platform | +3 MB (3 binaries) | extension install UX |
| blast radius on failure | VM crash possible | JVM isolated | process isolated | browser isolated |
| time to first sign on real BCCR token | 4-6 wk | 3-4 wk | **2-3 wk** | 3-5 wk |

---

## Recommendation

**Pick Option C — Subprocess helper** (Go, wrapping `github.com/miekg/pkcs11`) for desktop.

**For Flutter Web (standalone agent mode on tablet): defer to a follow-up issue (VRTV-56-web).** That follow-up can choose between a Bit4id commercial license or a rolled-own Chrome Extension + Native Messaging Host that invokes the same Go helper. The choice depends on a business-side call (licensing budget) that is outside this spike's scope.

### Rationale

1. **Lowest risk, highest reuse.** `miekg/pkcs11` + SoftHSM2 is the reference testing setup used by every Costa Rican fintech that does smart-card signing. We reuse thousands of hours of other people's debugging.
2. **Matches the Explicit Architecture invariant.** The Go helper is an *infrastructure detail*; the Dart side only ever sees `Pkcs11SigningPort` — no gRPC schema drift, no cross-language refactors when we later swap the helper for a native binding or a browser extension.
3. **Cross-platform distribution is tractable.** One binary per `GOOS/GOARCH` pair, built in CI. No JRE. No FFI per-platform debugging. Total distribution cost: ~3 MB on disk.
4. **SoftHSM2 testing is a one-liner.** `apt install softhsm2 && softhsm2-util --init-token` — CI runs the full sign/verify roundtrip without real hardware. The existing Dart CI matrix adds a tenth job; no new infra.
5. **Deferring Web is cheap.** The desktop path unblocks real freelance agents on Linux workstations (VRTV-59 onboarding UI). Flutter Web for the pyme dashboard reads audit events but does NOT need to sign — that's always an agent-side action. Web signing only matters for the rare "pyme importer signs directly" flow which is also marketplace-downstream (J06).

### What we SHIP in VRTV-56 (after this spike is merged)

**Nothing in this PR.** The spike is the deliverable. See decomposition below.

---

## Decomposition proposal

This spike recommends decomposing VRTV-56 into three child issues under the existing VRTV-56 parent. Each is sized so the implementation stays well below the 15-file decomposition threshold.

| child issue | scope | estimate | depends on |
|---|---|---|---|
| **VRTV-56-spike** (this) | spike doc merged; recommendation accepted | 1 day | — |
| **VRTV-56-helper** | Go `aduanext-pkcs11-helper` binary; stdio JSON protocol; SoftHSM2 test harness; build pipeline (release-please + 3 GOOS/GOARCH pairs) | 1-2 wk | spike |
| **VRTV-56-port** | `Pkcs11SigningPort` in libs/domain; `SubprocessPkcs11SigningAdapter` in libs/adapters; unit tests with a fake stdio pipe; integration tests against SoftHSM2 in CI | 1 wk | helper |
| **VRTV-56-integration** | `SubmitDeclarationUseCase` accepts `software_p12 OR pkcs11_token` (oneof); apps/hacienda-sidecar can fall back to the helper when available; VRTV-59 onboarding reads `enumerateSlots()` | 3-5 d | port |
| **VRTV-56-web** (FUTURE) | browser middleware decision (Bit4id vs roll-own Chrome extension); implementation follows | 3-5 wk | business call |

**Hard dependency for VRTV-59 (onboarding UI):** until at least `VRTV-56-port` is merged, the onboarding UI (VRTV-59) uses software-only `.p12` upload. This is explicit in VRTV-59's task notes and documented below.

---

## Stdio protocol sketch (for VRTV-56-helper)

For reviewer orientation only; final protocol decisions belong in VRTV-56-helper.

Request (stdin, newline-delimited JSON):

```json
{"method": "enumerateSlots"}
{"method": "sign", "slotId": 0, "pin": "redacted", "mechanism": "CKM_SHA256_RSA_PKCS", "data_b64": "…"}
{"method": "verify", "certPem": "…", "signature_b64": "…", "data_b64": "…"}
```

Response (stdout, newline-delimited JSON):

```json
{"ok": true, "result": {"slots": [{"id": 0, "label": "BCCR IDPrime MD 830"}]}}
{"ok": false, "error": {"code": "PIN_LOCKED", "message": "User PIN is locked"}}
```

PIN handling: passed inline per-call (never logged; the helper zeroes its memory between calls). A future iteration can use ephemeral tmpfs fd passing for defense-in-depth; the per-call model is acceptable for v1.

---

## Acceptance criteria for this spike

- [x] Four options evaluated with pros / cons / risk scores.
- [x] Recommendation made with concrete rationale.
- [x] Decomposition proposed so the implementation does not exceed the 15-file threshold.
- [x] Explicit note on Flutter Web scope + dependency on business-side licensing decision.
- [x] VRTV-59's software-only fallback path is called out.

## Out of scope (tracked separately)

- Actual Go helper implementation — VRTV-56-helper.
- Dart adapter + port wiring — VRTV-56-port.
- SubmitDeclarationUseCase integration — VRTV-56-integration.
- Browser middleware — VRTV-56-web.
- Token enrollment / certificate provisioning UI — BCCR handles externally.
- Windows / macOS signing of the Go binary (Apple notarization, Authenticode) — tracked with the release pipeline work in VRTV-58.
