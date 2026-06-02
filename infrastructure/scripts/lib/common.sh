#!/bin/bash
#
# Common library for AduaNext deployment / bootstrap scripts.
# Provides: logging, error handling, color output, common utilities.
#
# Ported faithfully from the sibling altrupets/monorepo so developers
# switching between repos share the same log style and helper surface.
#
# Usage:
#   source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
#
# Log verbosity is controlled with LOG_LEVEL (0=ERROR 1=WARN 2=INFO 3=DEBUG).
#

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color
readonly BOLD='\033[1m'

# Log levels
readonly LOG_LEVEL_ERROR=0
readonly LOG_LEVEL_WARN=1
readonly LOG_LEVEL_INFO=2
readonly LOG_LEVEL_DEBUG=3
LOG_LEVEL=${LOG_LEVEL:-2} # Default INFO

# ============================================
# Logging Functions
# ============================================

log_error() {
	if [[ $LOG_LEVEL -ge $LOG_LEVEL_ERROR ]]; then
		echo -e "${RED}❌ ERROR:${NC} $1" >&2
	fi
}

log_warn() {
	if [[ $LOG_LEVEL -ge $LOG_LEVEL_WARN ]]; then
		echo -e "${YELLOW}⚠️  WARN:${NC} $1"
	fi
}

log_info() {
	if [[ $LOG_LEVEL -ge $LOG_LEVEL_INFO ]]; then
		echo -e "${BLUE}ℹ️  INFO:${NC} $1"
	fi
}

log_success() {
	if [[ $LOG_LEVEL -ge $LOG_LEVEL_INFO ]]; then
		echo -e "${GREEN}✅ SUCCESS:${NC} $1"
	fi
}

log_debug() {
	if [[ $LOG_LEVEL -ge $LOG_LEVEL_DEBUG ]]; then
		echo -e "${CYAN}🔍 DEBUG:${NC} $1"
	fi
}

log_step() {
	local current="$1"
	local total="$2"
	local message="$3"
	echo -e "${BOLD}${BLUE}▶️  [${current}/${total}]${NC} ${message}"
}

log_header() {
	local message="$1"
	echo ""
	echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════${NC}"
	echo -e "${BOLD}${CYAN}  ${message}${NC}"
	echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════${NC}"
	echo ""
}

# ============================================
# Error Handling
# ============================================

cleanup_on_error() {
	local exit_code=$?
	local line_no=$1

	if [[ $exit_code -ne 0 ]]; then
		log_error "Script failed at line $line_no with exit code $exit_code"
		log_info "Check logs for more details"
	fi
	exit $exit_code
}

trap 'cleanup_on_error $LINENO' ERR

# ============================================
# Validation Functions
# ============================================

require_cmd() {
	local cmd="$1"
	local install_hint="${2:-}"

	if ! command -v "$cmd" &>/dev/null; then
		log_error "Required command not found: $cmd"
		if [[ -n "$install_hint" ]]; then
			log_info "Installation hint: $install_hint"
		fi
		exit 1
	fi
	log_debug "Command found: $cmd"
}

require_env() {
	local var="$1"
	local description="${2:-$var}"

	if [[ -z "${!var:-}" ]]; then
		log_error "Required environment variable not set: $var ($description)"
		exit 1
	fi
	log_debug "Environment variable set: $var"
}

validate_environment() {
	local env="$1"
	local valid_envs=("dev" "qa" "staging" "prod")

	for valid_env in "${valid_envs[@]}"; do
		if [[ "$env" == "$valid_env" ]]; then
			return 0
		fi
	done

	log_error "Invalid environment: $env"
	log_info "Valid environments: ${valid_envs[*]}"
	exit 1
}

# ============================================
# Kubernetes Helpers
# ============================================

wait_for_resource() {
	local resource="$1"
	local namespace="${2:-}"
	local timeout="${3:-300}"
	local ns_flag=""

	[[ -n "$namespace" ]] && ns_flag="-n $namespace"

	log_info "Waiting for $resource..."
	if ! kubectl wait --for=condition=ready "$resource" $ns_flag --timeout="${timeout}s" 2>/dev/null; then
		log_warn "Timeout waiting for $resource"
		return 1
	fi
	log_success "$resource is ready"
}

wait_for_namespace() {
	local namespace="$1"
	local timeout="${2:-60}"
	local start_time=$(date +%s)

	log_info "Waiting for namespace $namespace..."

	while true; do
		if kubectl get namespace "$namespace" &>/dev/null; then
			log_success "Namespace $namespace exists"
			return 0
		fi

		local current_time=$(date +%s)
		if ((current_time - start_time >= timeout)); then
			log_error "Timeout waiting for namespace $namespace"
			return 1
		fi

		sleep 2
	done
}

namespace_exists() {
	local namespace="$1"
	kubectl get namespace "$namespace" &>/dev/null
}

resource_exists() {
	local resource="$1"
	local namespace="${2:-}"
	local ns_flag=""

	[[ -n "$namespace" ]] && ns_flag="-n $namespace"

	kubectl get "$resource" $ns_flag &>/dev/null
}

# ============================================
# File & Directory Helpers
# ============================================

ensure_dir() {
	local dir="$1"
	if [[ ! -d "$dir" ]]; then
		mkdir -p "$dir"
		log_debug "Created directory: $dir"
	fi
}

get_script_dir() {
	cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

get_project_root() {
	local script_dir
	script_dir=$(get_script_dir)
	cd "$script_dir/../.." && pwd
}

# ============================================
# Time & Date Helpers
# ============================================

get_timestamp() {
	date +%Y%m%d-%H%M%S
}

get_iso_timestamp() {
	date -u +"%Y-%m-%dT%H:%M:%SZ"
}

format_duration() {
	local seconds="$1"
	local minutes=$((seconds / 60))
	local remaining_seconds=$((seconds % 60))

	if [[ $minutes -gt 0 ]]; then
		echo "${minutes}m ${remaining_seconds}s"
	else
		echo "${seconds}s"
	fi
}

# ============================================
# Confirmation Helpers
# ============================================

confirm() {
	local message="$1"
	local required_input="${2:-yes}"

	echo -e "${YELLOW}$message${NC}"
	echo -n "Type '$required_input' to confirm: "
	read -r user_input

	if [[ "$user_input" != "$required_input" ]]; then
		log_info "Operation cancelled"
		return 1
	fi
	return 0
}

confirm_destructive() {
	local env="$1"
	local action="${2:-destroy}"

	log_warn "⚠️  DESTRUCTIVE OPERATION"
	log_warn "Environment: $env"
	log_warn "Action: $action"
	echo ""

	if ! confirm "Are you sure you want to proceed?" "$env"; then
		exit 1
	fi
}

# ============================================
# Git Helpers
# ============================================

get_git_sha() {
	git rev-parse --short HEAD 2>/dev/null || echo "unknown"
}

get_git_branch() {
	git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown"
}

get_git_tag() {
	git describe --tags --exact-match 2>/dev/null || echo ""
}

# ============================================
# Docker/Image Helpers
# ============================================

get_image_tag() {
	local version="$1"
	local sha
	sha=$(get_git_sha)
	echo "${version}-${sha}"
}

# ============================================
# Export functions for use in other scripts
# ============================================

export -f log_error log_warn log_info log_success log_debug log_step log_header
export -f require_cmd require_env validate_environment
export -f wait_for_resource wait_for_namespace namespace_exists resource_exists
export -f ensure_dir get_script_dir get_project_root
export -f get_timestamp get_iso_timestamp format_duration
export -f confirm confirm_destructive
export -f get_git_sha get_git_branch get_git_tag
export -f get_image_tag
