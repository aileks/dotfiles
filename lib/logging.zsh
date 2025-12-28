[[ -n "${LOG_RED+x}" ]] && return 0

readonly LOG_RED='\033[0;31m'
readonly LOG_GREEN='\033[0;32m'
readonly LOG_YELLOW='\033[1;33m'
readonly LOG_BLUE='\033[0;34m'
readonly LOG_PURPLE='\033[0;35m'
readonly LOG_NC='\033[0m'

DRY_RUN=false
DEBUG_MODE=false

set_dry_run() {
    DRY_RUN=true
    log_info "DRY-RUN MODE: No changes will be made"
}

set_debug_mode() {
    DEBUG_MODE=true
}

log_debug() {
    if [[ "$DEBUG_MODE" == true ]]; then
        echo -e "${LOG_BLUE}[DEBUG]${LOG_NC} $1"
    fi
}

log_info() {
    echo -e "${LOG_BLUE}[INFO]${LOG_NC} $1"
}

log_success() {
    echo -e "${LOG_GREEN}[SUCCESS]${LOG_NC} $1"
}

log_warning() {
    echo -e "${LOG_YELLOW}[WARN]${LOG_NC} $1"
}

log_error() {
    echo -e "${LOG_RED}[ERROR]${LOG_NC} $1"
}

log_step() {
    echo -e "${LOG_PURPLE}[STEP]${LOG_NC} $1"
}

dry_run_or_execute() {
    local cmd="$1"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_debug "[DRY-RUN] Would execute: $cmd"
        return 0
    fi
    
    log_debug "[EXEC] $cmd"
    sh -c "$cmd"
}

dry_run_log() {
    if [[ "$DRY_RUN" != true ]]; then
        echo -e "${LOG_BLUE}[INFO]${LOG_NC} $1"
    fi
}
