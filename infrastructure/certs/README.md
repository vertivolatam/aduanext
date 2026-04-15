# BCCR trust bundle

`bccr-roots.pem` is the PEM-encoded bundle of Banco Central de Costa Rica
(BCCR) root + issuing CA certificates used by the XAdES-EPES verifier
pipeline (VRTV-58).

## Provenance

Official source:

> https://www.firmadigital.go.cr/repositorio/certificados.html

As of 2026-04, the published bundle includes (exact names may differ):

- **CA RAIZ NACIONAL DE COSTA RICA** — the national root
- **CA POLITICA SINPE — PERSONA FISICA** — issuing CA for personal certs
- **CA POLITICA SINPE — PERSONA JURIDICA** — issuing CA for corporate certs
- **CA POLITICA SINPE — FUNCIONARIO PUBLICO** — issuing CA for public
  servant certs
- **CA POLITICA SINPE — DNIE** — DNIE cards
- **CA POLITICA SINPE — AUTENTICACION** — authentication-only

## Status

> **Placeholder.** This PR (VRTV-58) ships the verification contract
> + `degraded` mode in the adapter. The real bundle + SHA-256
> fingerprint checks lands with VRTV-58b.

When VRTV-58b imports the real bundle, pin the SHA-256 fingerprint of
the PEM file in `infrastructure/certs/bccr-roots.pem.sha256` so an
accidental swap is caught at verifier boot.

## Rotation

The CA RAIZ NACIONAL is long-lived (multi-decade). Issuing CAs rotate
on a longer cadence than end-entity certs. Monitor the BCCR repository
quarterly for updates; the verifier **must** accept a parallel trust
bundle during rotation windows (previous + new) to avoid breaking
outstanding signatures.
