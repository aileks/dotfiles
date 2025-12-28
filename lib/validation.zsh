source "$SCRIPT_DIR/lib/logging.zsh"

check_prerequisites() {
    log_step "Running pre-flight checks"
    
    if ! ping -c 1 -W 3 "github.com" &>/dev/null; then
        log_error "No network connectivity to github.com"
        return 1
    fi
    
    local free_kb
    free_kb=$(df -k "$HOME" 2>/dev/null | awk 'NR==2 {print $4}' || echo "0")
    local free_gb=$((free_kb / 1024 / 1024))
    
    if [[ $free_gb -lt 5 ]]; then
        log_error "Insufficient disk space: ${free_gb}GB free (need 5GB)"
        return 1
    fi
    
    log_info "Disk space check: ${free_gb}GB available"
    
    if [[ ! -w "$HOME" ]]; then
        log_error "No write permission to home directory"
        return 1
    fi
    
    log_success "Prerequisites check passed"
    return 0
}

verify_brew_install() {
    if ! command_exists brew; then
        log_error "brew command not found after installation"
        return 1
    fi
    
    if ! brew --version &>/dev/null; then
        log_error "brew command not functional"
        return 1
    fi
    
    log_success "Homebrew verified and functional"
    return 0
}

verify_node_install() {
    if ! command_exists node; then
        log_error "node command not found"
        return 1
    fi
    
    if ! command_exists npm; then
        log_error "npm command not found"
        return 1
    fi
    
    log_success "Node.js $(node --version) and npm $(npm --version) verified"
    return 0
}

nvm_loaded() {
    type nvm &>/dev/null
}

load_nvm() {
    local nvm_sh
    if nvm_sh="$(brew --prefix nvm 2>/dev/null)/nvm.sh" && [[ -s "$nvm_sh" ]]; then
        source "$nvm_sh"
    elif [[ -s "$NVM_DIR/nvm.sh" ]]; then
        source "$NVM_DIR/nvm.sh"
    else
        return 1
    fi
    nvm_loaded
}
