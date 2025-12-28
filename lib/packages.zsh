source "$SCRIPT_DIR/lib/logging.zsh"
source "$SCRIPT_DIR/lib/validation.zsh"

install_xcode_tools() {
    show_progress "Installing Xcode Command Line Tools"
    
    if xcode-select -p &>/dev/null; then
        log_success "Xcode Command Line Tools already installed"
        return 0
    fi
    
    log_info "Installing Xcode Command Line Tools..."
    if ! xcode-select --install 2>/dev/null; then
        log_warning "Installation may already be in progress"
    fi
    
    local elapsed=0
    local wait_interval=60
    local timeout=3600
    
    while ! xcode-select -p &>/dev/null; do
        if [[ $elapsed -ge $timeout ]]; then
            log_error "Xcode Command Line Tools installation timed out after ${timeout}s"
            return 1
        fi
        log_info "Waiting for installation... (${elapsed}/${timeout}s)"
        sleep $wait_interval
        elapsed=$((elapsed + wait_interval))
    done
    
    log_success "Xcode Command Line Tools installed"
}

install_homebrew() {
    show_progress "Setting up Homebrew"
    
    if command_exists brew; then
        log_info "Homebrew already installed, updating..."
        dry_run_or_execute "brew update"
        verify_brew_install || return 1
        log_success "Homebrew updated"
        return 0
    fi
    
    log_info "Installing Homebrew..."
    local install_url="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
    local install_script
    install_script=$(mktemp)

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would download and execute Homebrew install script from $install_url"
    else
        log_debug "Downloading Homebrew install script..."
        if ! curl -fsSL "$install_url" -o "$install_script"; then
            log_error "Failed to download Homebrew install script"
            rm -f "$install_script"
            return 1
        fi

        log_debug "Verifying install script..."
        if ! grep -q "Homebrew" "$install_script" 2>/dev/null; then
            log_error "Install script verification failed: invalid content"
            rm -f "$install_script"
            return 1
        fi

        log_debug "Executing Homebrew install script..."
        if ! bash "$install_script"; then
            log_error "Failed to execute Homebrew install script"
            rm -f "$install_script"
            return 1
        fi

        rm -f "$install_script"
    fi
    
    if command_exists brew; then
        local brew_prefix
        brew_prefix=$(brew --prefix 2>/dev/null)

        if [[ -n "$brew_prefix" ]]; then
            if [[ -f "$HOME/.zprofile" ]]; then
                if ! grep -q "$brew_prefix/bin/brew" "$HOME/.zprofile" 2>/dev/null; then
                    dry_run_or_execute "echo 'eval \"\$($brew_prefix/bin/brew shellenv)\"' >> '$HOME/.zprofile'"
                fi
            else
                dry_run_or_execute "echo 'eval \"\$($brew_prefix/bin/brew shellenv)\"' >> '$HOME/.zprofile'"
            fi
            dry_run_or_execute "eval \"\$($brew_prefix/bin/brew shellenv)\""
        fi
    fi
    
    verify_brew_install || return 1
    log_success "Homebrew installed successfully"
}

install_packages() {
    show_progress "Installing packages from Brewfile"
    
    local brewfile_path="$DOTFILES_DIR/Brewfile"
    
    if [[ ! -f "$brewfile_path" ]]; then
        log_error "Brewfile not found: $brewfile_path"
        return 1
    fi
    
    log_info "Installing packages from Brewfile..."
    
    local output_file
    output_file=$(mktemp)
    
    if brew bundle install --file="$brewfile_path" 2>&1 | tee "$output_file"; then
        log_success "All packages installed successfully"
        rm "$output_file"
        return 0
    else
        log_warning "Some packages failed to install"
        log_info "Check installation log: $output_file"
        return 1
    fi
}

install_node() {
    show_progress "Setting up Node.js"
    
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    dry_run_or_execute "mkdir -p '$NVM_DIR'"
    
    if ! nvm_loaded; then
        if command_exists brew; then
            if ! brew list --formula nvm &>/dev/null; then
                log_info "Installing nvm via Homebrew..."
                if ! dry_run_or_execute "brew install nvm"; then
                    log_error "Failed to install nvm"
                    return 1
                fi
            fi
            load_nvm
        fi
    fi
    
    if ! nvm_loaded; then
        log_warning "nvm is not available; skipping Node installation"
        log_info "Ensure your shell loads nvm and run: nvm install --lts"
        return 0
    fi
    
    if [[ "$DRY_RUN" != true ]]; then
        local NODE_VERSION="22"
        log_info "Installing Node.js $NODE_VERSION..."
        if ! nvm install "$NODE_VERSION" 2>&1; then
            log_error "Failed to install Node.js $NODE_VERSION"
            return 1
        fi

        nvm use "$NODE_VERSION"
        
        log_info "Installing pnpm..."
        if ! npm install --global corepack@latest 2>&1; then
            log_error "Failed to install corepack"
            return 1
        fi
        
        corepack enable pnpm
        corepack use pnpm@10.0.0
        
        verify_node_install || return 1
        log_success "Node.js and pnpm installed successfully"
    else
        log_info "[DRY-RUN] Would install Node.js LTS and pnpm"
    fi
}
