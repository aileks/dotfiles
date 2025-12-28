source "$SCRIPT_DIR/lib/logging.zsh" 2>/dev/null || true

command_exists() {
    command -v "$1" &>/dev/null
    return $?
}

wait_for_user() {
    local message="$1"
    echo -e "${LOG_YELLOW}$message${LOG_NC}"
    read -p "Press Enter to continue..."
}

safe_git_clone() {
    local url="$1"
    local dest="$2"
    local retries="${3:-3}"
    local delay="${4:-5}"
    local i=1
    
    while [[ $i -le $retries ]]; do
        if dry_run_or_execute "git clone '$url' '$dest'"; then
            return 0
        fi
        log_warning "Git clone failed (attempt $i/$retries)"
        if [[ $i -lt $retries ]]; then
            sleep $delay
        fi
        i=$((i + 1))
    done
    log_error "Failed to clone $url after $retries attempts"
    return 1
}

verify_symlink() {
    local src="$1"
    local dest="$2"
    
    if [[ ! -L "$dest" ]]; then
        log_error "Symlink not created: $dest"
        return 1
    fi
    
    local resolved
    resolved=$(readlink "$dest")
    if [[ "$resolved" != "$src" ]]; then
        log_error "Symlink points to wrong location: $resolved (expected: $src)"
        return 1
    fi
    
    return 0
}
