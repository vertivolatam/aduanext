# Makefile — `bootstrap-dev` + altrupets-style naming

**Date:** 2026-04-23
**Author:** Andres Pena (via brainstorming)
**Status:** Approved — ready for implementation plan

## Goal

Enable `make bootstrap-dev` to bring AduaNext up locally: Minikube cluster running
with infra (postgres + redis + keycloak via the existing Helm umbrella chart)
and the Flutter desktop app open on Linux.

Align target naming with the convention used in the sibling `altrupets/monorepo`
Makefile (`env-recurso-verbo`) so developers switching between repos share
muscle memory.

## Non-goals

- Containerizing `apps/server` (Dart) — that work belongs to VRTV-58.
- Adopting Terraform + Kustomize (altrupets's deployment tooling). AduaNext keeps
  its Helm umbrella chart.
- Adopting Infisical for secret sync.
- Adding QA / stage / prod targets. Only `dev-*` targets exist today.
- Creating a `launch_flutter_debug.sh` companion script — the 3-line Makefile
  target suffices until Android / iOS launchers are needed.

## Decisions

- **Model C (minimal infra-only):** Minikube hosts postgres + redis + keycloak
  via the umbrella Helm chart. Server Dart stays on the host (not launched by
  `bootstrap-dev`). Flutter desktop connects to keycloak through a port-forward.
- **Naming: full rename (option B).** No deprecated aliases. The 8 files
  outside the Makefile that reference old target names are updated in the same
  commit.
- **`bootstrap-dev` is destructive at the start** (parity with altrupets): it
  runs `dev-minikube-destroy` first for idempotency. Re-running rebuilds from
  scratch at the cost of ~2 min.
- **Flutter runs in foreground** at the end of `bootstrap-dev`. Ctrl-C or `q`
  in the Flutter process returns control to the shell.
- **`bootstrap-dev` only port-forwards keycloak** (not postgres / redis). If the
  developer later runs `apps/server` on the host, they expose whatever they
  need manually. YAGNI.

## Target rename map

| Old | New | Behaviour change |
|---|---|---|
| `db-up` | `dev-compose-up` | none |
| `db-down` | `dev-compose-down` | none |
| `db-reset` | `dev-compose-reset` | none |
| `db-psql` | `dev-compose-psql` | none |
| `db-psql-test` | `dev-compose-psql-test` | none |
| `db-verify-pgvector` | `dev-compose-verify-pgvector` | none |
| `test-dart` | `dev-test-dart` | none |
| `test-dart-domain` | `dev-test-dart-domain` | none |
| `test-dart-adapters` | `dev-test-dart-adapters` | none |
| `images-pull` | `dev-images-pull` | none |
| `minikube-up` | `dev-minikube-deploy` | none |
| `minikube-down` | `dev-minikube-stop` | none |
| `minikube-delete` | `dev-minikube-destroy` | none |
| `minikube-status` | `dev-minikube-status` | none |
| `helm-deps` | `dev-helm-deps` | none |
| `helm-lint` | `dev-helm-lint` | none |
| `helm-template` | `dev-helm-template` | none |
| `helm-install` | `dev-helm-deploy` | none |
| `helm-uninstall` | `dev-helm-destroy` | none |
| `k8s-logs` | `dev-k8s-logs` | none |
| `argocd-install` | `dev-argocd-deploy` | none |
| `argocd-uninstall` | `dev-argocd-destroy` | none |
| `argocd-app-create` | `dev-argocd-app-deploy` | none |
| `argocd-app-delete` | `dev-argocd-app-destroy` | none |
| `argocd-port-forward` | `dev-argocd-port-forward` | none |
| `argocd-admin-password` | `dev-argocd-password` | none |
| `argocd-sync` | `dev-argocd-sync` | none |
| `harbor-install` | `dev-harbor-deploy` | none |
| `harbor-uninstall` | `dev-harbor-destroy` | none |
| `harbor-ui` | `dev-harbor-ui` | none |
| `harbor-admin-password` | `dev-harbor-password` | none |
| `harbor-login` | `dev-harbor-login` | none |
| `harbor-push-server` | `dev-harbor-push-server` | none |

## New targets

### `dev-setup`
Verifies required CLIs (`kubectl`, `helm`, `minikube`, `flutter`) are on PATH
and installs pre-commit hooks if pre-commit is available. Non-blocking when
pre-commit is missing. Fails fast when any required CLI is missing.

### `dev-keycloak-start` / `dev-keycloak-stop`
Port-forwards the keycloak subchart service to `localhost:$KEYCLOAK_PORT` in
the background. The start target kills any pre-existing port-forward against
the same service before starting a new one (idempotent re-runs).

Variables:
- `KEYCLOAK_PORT ?= 8192` (matches the port used by docker-compose for
  developer parity).
- `KEYCLOAK_SVC ?= aduanext-keycloak` (bitnami chart convention:
  `<release>-<chartname>`). This value is verified against `kubectl get svc -n
  aduanext` during implementation — if the bitnami naming differs, the
  variable is adjusted.
- Target port is `80` (the bitnami keycloak service exposes HTTP on port 80).
  The implementation verifies this too.

### `dev-mobile-launch-desktop`
```
cd apps/mobile && flutter pub get && flutter run -d linux
```

### `dev-mobile-launch-web`
```
cd apps/mobile && flutter pub get && flutter run -d chrome
```

### `dev-mobile-launch`
Alias for `dev-mobile-launch-desktop`.

### `bootstrap-dev`
Chains, in order:

1. `dev-minikube-destroy` (with `|| true` so it is a no-op on fresh machines)
2. `dev-setup`
3. `dev-minikube-deploy`
4. `dev-helm-deps`
5. `dev-helm-deploy`
6. `dev-keycloak-start`
7. `dev-mobile-launch-desktop` (foreground; exits when user quits Flutter)

## Help organization

The existing `help` target (awk-based parser of `## ` comments) stays
unchanged in mechanics. Section headers in the Makefile are restructured so
`make help` renders grouped like altrupets:

```
DEV - Setup
DEV - Compose
DEV - Tests
DEV - Images
DEV - Minikube
DEV - Helm
DEV - Keycloak
DEV - ArgoCD
DEV - Harbor
DEV - Mobile
Bootstrap
```

## Collateral updates (same commit)

Find-and-replace the old target names in these files:

| File | References |
|---|---|
| `README.md` | ~12 mentions across db-*, minikube-*, helm-*, argocd-*, harbor-* |
| `apps/server/README.md` | `make db-up` (line 25) |
| `infrastructure/argocd/README.md` | 7 mentions (argocd-*, helm-install) — preserve historical narrative in the "Migrating from manual `make helm-install` to GitOps" section but update the executable commands. |
| `infrastructure/argocd/install.yaml` | comment on line 3 |
| `infrastructure/harbor/README.md` | 5 mentions (harbor-*) |
| `infrastructure/harbor/install.sh` | 4 `echo` lines (27-29) |
| `infrastructure/helm-charts/aduanext/values.yaml` | comment on line 6 (`make helm-install`) |
| `docker-compose.yaml` | line 9 (`Usage: make db-up (see ../Makefile)` — also fix the stale `../Makefile` path to `./Makefile`) |

## Verification

1. `make help` renders the grouped listing without errors.
2. `make bootstrap-dev` on a machine with an empty `~/.minikube/profiles/aduanext`
   completes and opens the Flutter desktop window against a Keycloak reachable
   at `http://localhost:8192`.
3. `make dev-keycloak-stop` followed by `make dev-keycloak-start` leaves a
   single `kubectl port-forward` process running (not two).
4. No file in the repo references any of the old target names after the
   commit, verified with `grep -rnE "make (db-up|minikube-up|helm-install|
   argocd-install|harbor-install|test-dart|k8s-logs)"` returning no hits.

## Risks

- **Bitnami service name drift:** if `aduanext-keycloak` is not the correct
  subchart service name, `dev-keycloak-start` silently fails (port-forward to
  a non-existent service). Mitigated by verifying with `kubectl get svc -n
  aduanext` during implementation and pinning the right name in the Makefile.
- **`helm dependency update` is network-bound:** on a laptop with flaky
  internet, `bootstrap-dev` stalls on `dev-helm-deps`. Acceptable — altrupets
  has the same risk on `tofu init`.
- **Flutter desktop on Linux requires GTK headers:** the target assumes the
  dev has already passed `flutter doctor` for the Linux desktop target.
  `dev-setup` checks that the `flutter` binary exists but does not run
  `flutter doctor`. If `flutter run -d linux` fails with missing libraries,
  the error surfaces from the Flutter toolchain itself.

## Out of scope (captured for the future)

- Script `apps/mobile/launch_flutter_debug.sh` with Android / emulator
  support — add when the mobile work starts needing it.
- Exposing postgres / redis via port-forward — add as dedicated
  `dev-postgres-start` / `dev-redis-start` targets when someone needs the
  host-side server Dart flow.
- Full cluster-complete mode (model B) — reachable once VRTV-58 ships the
  server Dockerfile and the umbrella chart's placeholder deployments point
  at a real image.
