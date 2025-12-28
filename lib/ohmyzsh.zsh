source "$SCRIPT_DIR/lib/logging.zsh"
source "$SCRIPT_DIR/lib/utils.zsh"

install_oh_my_zsh() {
    show_progress "Setting up Oh-My-Zsh"
    
    local omz_dir="$HOME/.oh-my-zsh"
    local custom_dir="${ZSH_CUSTOM:-$omz_dir/custom}"
    
    if [[ ! -d "$omz_dir" ]]; then
        log_info "Installing Oh-My-Zsh..."
        local install_url="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
        local install_script
        install_script=$(mktemp)

        if [[ "$DRY_RUN" == true ]]; then
            log_info "[DRY-RUN] Would download and execute Oh-My-Zsh install script from $install_url"
        else
            log_debug "Downloading Oh-My-Zsh install script..."
            if ! curl -fsSL "$install_url" -o "$install_script"; then
                log_error "Failed to download Oh-My-Zsh install script"
                rm -f "$install_script"
                return 1
            fi

            log_debug "Verifying install script..."
            if ! grep -q "oh-my-zsh" "$install_script" 2>/dev/null; then
                log_error "Install script verification failed: invalid content"
                rm -f "$install_script"
                return 1
            fi

            local script_size
            script_size=$(wc -c < "$install_script" 2>/dev/null || echo "0")
            if [[ "$script_size" -lt 5000 ]]; then
                log_error "Install script too small ($script_size bytes), may be invalid"
                rm -f "$install_script"
                return 1
            fi

            log_debug "Executing Oh-My-Zsh install script..."
            if ! RUNZSH=no CHSH=no sh "$install_script"; then
                log_error "Failed to execute Oh-My-Zsh install script"
                rm -f "$install_script"
                return 1
            fi

            rm -f "$install_script"
        fi
        log_success "Oh-My-Zsh installed successfully"
    else
        log_info "Oh-My-Zsh already installed"
    fi
    
    local autosuggestions_dir="$custom_dir/plugins/zsh-autosuggestions"
    if [[ ! -d "$autosuggestions_dir" ]]; then
        log_info "Installing zsh-autosuggestions..."
        safe_git_clone "https://github.com/zsh-users/zsh-autosuggestions" "$autosuggestions_dir" || return 1
    else
        log_info "zsh-autosuggestions already installed"
    fi
    
    local syntax_dir="$custom_dir/plugins/fast-syntax-highlighting"
    if [[ ! -d "$syntax_dir" ]]; then
        log_info "Installing fast-syntax-highlighting..."
        safe_git_clone "https://github.com/zdharma-continuum/fast-syntax-highlighting.git" "$syntax_dir" || return 1
    else
        log_info "fast-syntax-highlighting already installed"
    fi
    
    log_success "Oh-My-Zsh and plugins configured"
}
