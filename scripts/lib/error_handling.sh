#!/usr/bin/env bash
# =============================================================================
# File: scripts/lib/error_handling.sh
# Purpose: Centralized error handling, logging, and rollback mechanisms
# Usage: source scripts/lib/error_handling.sh
# =============================================================================

# Ensure this script is sourced, not executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "ERROR: This script must be sourced, not executed directly."
  echo "Usage: source ${BASH_SOURCE[0]}"
  exit 1
fi

# Enable strict error handling (can be overridden by sourcing script if needed)
set -euo pipefail

# =============================================================================
# Color Definitions for Output
# =============================================================================
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# =============================================================================
# Exit Code Definitions
# =============================================================================
readonly EXIT_SUCCESS=0
readonly EXIT_GENERAL_ERROR=1
readonly EXIT_MISSING_PREREQ=2
readonly EXIT_VALIDATION_FAILED=3
readonly EXIT_NETWORK_ERROR=4
readonly EXIT_TIMEOUT=5
readonly EXIT_USER_CANCELLED=6
readonly EXIT_CONFIG_ERROR=7
readonly EXIT_PERMISSION_ERROR=8

# =============================================================================
# Global Variables
# =============================================================================
SCRIPT_NAME="${SCRIPT_NAME:-$(basename "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}" 2>/dev/null || echo "unknown")}"
LOG_LEVEL="${LOG_LEVEL:-INFO}"  # DEBUG, INFO, WARN, ERROR
CLEANUP_FUNCTIONS=()
ROLLBACK_FUNCTIONS=()
ERROR_COUNT=0
VERBOSE="${VERBOSE:-false}"

# =============================================================================
# Logging Functions
# =============================================================================

# Log a debug message (only shown if LOG_LEVEL=DEBUG or VERBOSE=true)
log_debug() {
  if [[ "$LOG_LEVEL" == "DEBUG" ]] || [[ "$VERBOSE" == "true" ]]; then
    echo -e "${CYAN}[DEBUG]${NC} $*" >&2
  fi
}

# Log an informational message
log_info() {
  echo -e "${BLUE}[INFO]${NC} $*"
}

# Log a success message
log_success() {
  echo -e "${GREEN}[✓]${NC} $*"
}

# Log a warning message
log_warn() {
  echo -e "${YELLOW}[WARNING]${NC} $*" >&2
}

# Log an error message
log_error() {
  ((ERROR_COUNT++)) || true
  echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Log a fatal error and exit
log_fatal() {
  local exit_code="${2:-$EXIT_GENERAL_ERROR}"
  echo -e "${RED}[FATAL]${NC} $1" >&2
  exit "$exit_code"
}

# =============================================================================
# Error Handling Functions
# =============================================================================

# Display error with context and exit
# Usage: error_exit "Error message" [exit_code]
error_exit() {
  local message="$1"
  local exit_code="${2:-$EXIT_GENERAL_ERROR}"
  
  log_error "$message"
  log_error "Script: $SCRIPT_NAME"
  log_error "Line: ${BASH_LINENO[0]}"
  log_error "Function: ${FUNCNAME[1]}"
  
  exit "$exit_code"
}

# Handle errors with detailed context
# Usage: Automatically called on ERR trap
error_handler() {
  local line_no="$1"
  local bash_lineno="$2"
  local last_command="$3"
  local exit_code="$4"
  
  log_error "Command failed with exit code $exit_code"
  log_error "Failed command: $last_command"
  log_error "Line number: $line_no"
  log_error "Function: ${FUNCNAME[2]:-main}"
  
  # Execute rollback functions if any
  execute_rollback_functions
  
  exit "$exit_code"
}

# =============================================================================
# Cleanup and Rollback Functions
# =============================================================================

# Register a cleanup function to be called on exit
# Usage: register_cleanup_function "function_name" [args...]
register_cleanup_function() {
  local func="$*"
  CLEANUP_FUNCTIONS+=("$func")
  log_debug "Registered cleanup function: $func"
}

# Register a rollback function to be called on error
# Usage: register_rollback_function "function_name" [args...]
register_rollback_function() {
  local func="$*"
  ROLLBACK_FUNCTIONS+=("$func")
  log_debug "Registered rollback function: $func"
}

# Execute all registered cleanup functions
execute_cleanup_functions() {
  if [[ ${#CLEANUP_FUNCTIONS[@]} -gt 0 ]]; then
    log_info "Executing cleanup functions..."
    for func in "${CLEANUP_FUNCTIONS[@]}"; do
      log_debug "Running cleanup: $func"
      eval "$func" || log_warn "Cleanup function failed: $func"
    done
  fi
}

# Execute all registered rollback functions
execute_rollback_functions() {
  if [[ ${#ROLLBACK_FUNCTIONS[@]} -gt 0 ]]; then
    log_warn "Executing rollback functions..."
    for func in "${ROLLBACK_FUNCTIONS[@]}"; do
      log_debug "Running rollback: $func"
      eval "$func" || log_warn "Rollback function failed: $func"
    done
  fi
}

# =============================================================================
# Trap Handlers
# =============================================================================

# Exit trap handler
cleanup_trap() {
  local exit_code=$?
  
  # Don't run cleanup on successful exit if already run
  if [[ $exit_code -eq 0 ]]; then
    log_debug "Script completed successfully"
  else
    log_error "Script exited with code $exit_code"
  fi
  
  execute_cleanup_functions
  
  exit "$exit_code"
}

# Error trap handler
error_trap() {
  error_handler "${BASH_LINENO[0]}" "${BASH_LINENO[1]}" "$BASH_COMMAND" "$?"
}

# Interrupt trap handler (Ctrl+C)
interrupt_trap() {
  log_warn "Script interrupted by user"
  execute_rollback_functions
  execute_cleanup_functions
  exit "$EXIT_USER_CANCELLED"
}

# Termination trap handler
terminate_trap() {
  log_warn "Script terminated"
  execute_rollback_functions
  execute_cleanup_functions
  exit "$EXIT_GENERAL_ERROR"
}

# =============================================================================
# Trap Setup
# =============================================================================

# Setup all trap handlers
setup_error_handling() {
  trap cleanup_trap EXIT
  trap error_trap ERR
  trap interrupt_trap INT
  trap terminate_trap TERM
  
  log_debug "Error handling initialized for $SCRIPT_NAME"
}

# =============================================================================
# Validation Functions
# =============================================================================

# Check if a command exists
# Usage: require_command "kubectl" "Please install kubectl"
require_command() {
  local cmd="$1"
  local message="${2:-Command '$cmd' is required but not found}"
  
  if ! command -v "$cmd" &> /dev/null; then
    error_exit "$message" "$EXIT_MISSING_PREREQ"
  fi
  
  log_debug "Required command found: $cmd"
}

# Check if a variable is set
# Usage: require_var "MY_VAR" "MY_VAR must be set"
require_var() {
  local var_name="$1"
  local message="${2:-Required variable '$var_name' is not set}"
  
  if [[ -z "${!var_name:-}" ]]; then
    error_exit "$message" "$EXIT_CONFIG_ERROR"
  fi
  
  log_debug "Required variable set: $var_name=${!var_name}"
}

# Check if a file exists
# Usage: require_file "/path/to/file" "File not found"
require_file() {
  local file="$1"
  local message="${2:-Required file not found: $file}"
  
  if [[ ! -f "$file" ]]; then
    error_exit "$message" "$EXIT_CONFIG_ERROR"
  fi
  
  log_debug "Required file exists: $file"
}

# Check if a directory exists
# Usage: require_directory "/path/to/dir" "Directory not found"
require_directory() {
  local dir="$1"
  local message="${2:-Required directory not found: $dir}"
  
  if [[ ! -d "$dir" ]]; then
    error_exit "$message" "$EXIT_CONFIG_ERROR"
  fi
  
  log_debug "Required directory exists: $dir"
}

# =============================================================================
# Retry Mechanism
# =============================================================================

# Retry a command with exponential backoff
# Usage: retry_command 3 5 "kubectl get pods"
retry_command() {
  local max_attempts="$1"
  local delay="$2"
  shift 2
  local command="$*"
  local attempt=1
  
  while [[ $attempt -le $max_attempts ]]; do
    log_debug "Attempt $attempt/$max_attempts: $command"
    
    if eval "$command"; then
      log_debug "Command succeeded on attempt $attempt"
      return 0
    fi
    
    if [[ $attempt -lt $max_attempts ]]; then
      log_warn "Command failed, retrying in ${delay}s... (attempt $attempt/$max_attempts)"
      sleep "$delay"
      delay=$((delay * 2))  # Exponential backoff
    fi
    
    ((attempt++)) || true
  done
  
  log_error "Command failed after $max_attempts attempts: $command"
  return 1
}

# =============================================================================
# Progress Tracking
# =============================================================================

# Display a progress message
# Usage: show_progress "Installing dependencies"
show_progress() {
  echo -e "${MAGENTA}▶${NC} $*"
}

# Display a section header
# Usage: show_section "Validation Phase"
show_section() {
  echo ""
  echo -e "${CYAN}========================================${NC}"
  echo -e "${CYAN}$*${NC}"
  echo -e "${CYAN}========================================${NC}"
}

# =============================================================================
# Helper Functions
# =============================================================================

# Prompt user for confirmation
# Usage: confirm "Do you want to continue?" || exit 1
confirm() {
  local message="${1:-Are you sure?}"
  local response
  
  read -r -p "$message (y/N): " response
  case "$response" in
    [yY][eE][sS]|[yY])
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Check if running as root
# Usage: require_root
require_root() {
  if [[ $EUID -ne 0 ]]; then
    error_exit "This script must be run as root" "$EXIT_PERMISSION_ERROR"
  fi
}

# Check if NOT running as root
# Usage: prevent_root
prevent_root() {
  if [[ $EUID -eq 0 ]]; then
    error_exit "This script should not be run as root" "$EXIT_PERMISSION_ERROR"
  fi
}

# =============================================================================
# Initialization
# =============================================================================

# Automatically setup error handling when sourced (unless SKIP_TRAP_SETUP is set)
if [[ "${SKIP_TRAP_SETUP:-0}" != "1" ]]; then
  setup_error_handling
fi

# Export commonly used functions
export -f log_debug log_info log_success log_warn log_error log_fatal
export -f error_exit require_command require_var require_file require_directory
export -f retry_command show_progress show_section confirm
