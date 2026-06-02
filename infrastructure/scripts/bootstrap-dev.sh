#!/bin/bash
#
# AduaNext — bootstrap-dev wrapper.
#
# Brings AduaNext up locally (Model C: Minikube hosting postgres + redis +
# keycloak via the Helm umbrella chart) and opens the Flutter desktop app.
#
# This wrapper does NOT contain deployment logic. It orchestrates the REAL
# Makefile targets (`make <target>`) phase by phase, emitting altrupets-style
# logs via infrastructure/scripts/lib/common.sh and tee-ing everything
# (stdout + stderr) to a per-run log file under logs/bootstrap/.
#
# Invoked by: `make bootstrap-dev`
#

# Resolve project root (two levels up from this script) and source the lib.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=infrastructure/scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

cd "$PROJECT_ROOT"

# Per-run log file (altrupets convention: logs/<component>/<name>-<timestamp>.log)
LOG_DIR="$PROJECT_ROOT/logs/bootstrap"
ensure_dir "$LOG_DIR"
LOG_FILE="$LOG_DIR/bootstrap-dev-$(get_timestamp).log"

# Tee EVERYTHING (stdout + stderr) from here on to the log file AND the console.
exec > >(tee -a "$LOG_FILE") 2>&1

log_header "AduaNext — bootstrap-dev"
log_info "Project root: $PROJECT_ROOT"
log_info "Log file:     $LOG_FILE"
log_info "Branch:       $(get_git_branch) @ $(get_git_sha)"

# ------------------------------------------------------------------
# Phases — REAL aduanext Makefile targets, run in order.
# Each entry is "make-target|Human description". Keep deployment logic
# in the Makefile; this wrapper only sequences + logs it.
# ------------------------------------------------------------------
PHASES=(
	"minikube-delete|Destroy any existing Minikube cluster (idempotent reset)"
	"minikube-up|Start Minikube cluster (ingress + metrics)"
	"helm-deps|Update Helm umbrella chart dependencies"
	"helm-install|Deploy postgres + redis + keycloak via Helm"
	"db-up|Start docker-compose postgres + redis (dev + test)"
)

# The Flutter desktop launch runs in the FOREGROUND as the final phase and
# returns control to the shell when the developer quits Flutter.
FINAL_PHASE="dev-mobile-launch-desktop|Launch Flutter desktop app (foreground)"

# Total = orchestrated phases + the final foreground launch.
TOTAL=$(( ${#PHASES[@]} + 1 ))

run_phase() {
	local idx="$1"
	local target="$2"
	local desc="$3"
	local allow_fail="${4:-false}"

	log_step "$idx" "$TOTAL" "$desc  (make $target)"

	if make "$target"; then
		log_success "Phase $idx/$TOTAL complete: $target"
	else
		local rc=$?
		if [[ "$allow_fail" == "true" ]]; then
			log_warn "Phase $idx/$TOTAL ($target) failed with exit $rc — continuing (allowed to fail)"
		else
			log_error "Phase $idx/$TOTAL ($target) failed with exit $rc"
			log_info "Full log: $LOG_FILE"
			exit $rc
		fi
	fi
}

i=0
for entry in "${PHASES[@]}"; do
	i=$((i + 1))
	target="${entry%%|*}"
	desc="${entry#*|}"

	# The destructive reset is a no-op on fresh machines — allow it to fail.
	if [[ "$target" == "minikube-delete" ]]; then
		run_phase "$i" "$target" "$desc" "true"
	else
		run_phase "$i" "$target" "$desc"
	fi
done

# Final foreground phase: Flutter desktop.
i=$((i + 1))
final_target="${FINAL_PHASE%%|*}"
final_desc="${FINAL_PHASE#*|}"
log_step "$i" "$TOTAL" "$final_desc  (make $final_target)"
make "$final_target"

log_success "bootstrap-dev finished. Full log written to: $LOG_FILE"
