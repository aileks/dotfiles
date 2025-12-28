source "$SCRIPT_DIR/lib/logging.zsh"
source "$SCRIPT_DIR/lib/utils.zsh"

install_oh_my_zsh() {
    show_progress "Setting up Oh-My-Zsh"
    
    local omz_dir="$HOME/.oh-my-zsh"
    local custom_dir="${ZSH_CUSTOM:-$omz_dir/custom}"
    
    if [[ ! -d "$omz_dir" ]]; then
        log_info "Installing Oh-My-Zsh..."
        local install_url="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
        if ! dry_run_or_execute "RUNZSH=no CHSH=no sh -c \"\$(curl -fsSL $install_url)\""; then
            log_error "Failed to install Oh-My-Zsh"
            return 1
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
