source "$SCRIPT_DIR/lib/logging.zsh"
source "$SCRIPT_DIR/lib/utils.zsh"

SYMLINK_MAPPINGS=(
    "zed/settings.json:$HOME/.config/zed/settings.json"
    "zed/keymap.json:$HOME/.config/zed/keymap.json"
    "zed/themes:$HOME/.config/zed/themes"
    "zsh/zshrc:$HOME/.zshrc"
    "nvim:$HOME/.config/nvim"
    "fastfetch:$HOME/.config/fastfetch"
    "ghostty:$HOME/.config/ghostty"
    "aerospace:$HOME/.config/aerospace"
    "tmux/tmux.conf:$HOME/.tmux.conf"
)

create_symlink() {
    local src="$1"
    local dest="$2"
    
    local dest_dir
    dest_dir=$(dirname "$dest")
    
    if [[ ! -d "$dest_dir" ]]; then
        dry_run_or_execute "mkdir -p '$dest_dir'"
        dry_run_log "Created directory: $dest_dir"
    fi
    
    if [[ -e "$dest" && ! -L "$dest" ]] || [[ -L "$dest" && ! -e "$dest" ]]; then
        dry_run_log "Backing up existing file/directory: $dest"
        dry_run_or_execute "mv '$dest' '${dest}${BACKUP_SUFFIX}'"
    elif [[ -L "$dest" ]]; then
        dry_run_log "Removing existing symlink: $dest"
        dry_run_or_execute "rm '$dest'"
    fi
    
    if dry_run_or_execute "ln -s '$src' '$dest'"; then
        if [[ "$DRY_RUN" != true ]]; then
            if verify_symlink "$src" "$dest"; then
                log_success "Created symlink: $dest -> $src"
            else
                return 1
            fi
        else
            log_success "[DRY-RUN] Would create symlink: $dest -> $src"
        fi
    else
        log_error "Failed to create symlink: $dest -> $src"
        return 1
    fi
}

_update_dotfiles_repo() {
    if [[ -d "$DOTFILES_DIR" ]]; then
        log_info "Dotfiles directory already exists, updating..."
        if ! dry_run_or_execute "cd '$DOTFILES_DIR' && git pull origin main"; then
            log_warning "Failed to update dotfiles, continuing with existing version"
            return 0
        fi
        log_success "Dotfiles updated successfully"
    else
        log_info "Cloning dotfiles repository..."
        if ! safe_git_clone "$DOTFILES_REPO" "$DOTFILES_DIR"; then
            log_error "Failed to clone dotfiles repository"
            return 1
        fi
        log_success "Dotfiles cloned successfully"
    fi
}

_init_submodules() {
    log_info "Initializing git submodules..."
    
    if ! dry_run_or_execute "cd '$DOTFILES_DIR' && git submodule update --init --recursive"; then
        log_warning "Failed to initialize git submodules, continuing anyway"
        return 1
    fi
    
    log_success "Git submodules initialized successfully"
}

_create_symlinks() {
    log_info "Creating symlinks..."
    
    dry_run_or_execute "mkdir -p '$HOME/.config/zed'"
    
    local mapping src dest full_src
    for mapping in "${SYMLINK_MAPPINGS[@]}"; do
        src="${mapping%%:*}"
        dest="${mapping##*:}"
        full_src="$DOTFILES_DIR/$src"
        
        if [[ -e "$full_src" ]]; then
            create_symlink "$full_src" "$dest"
        else
            log_warning "Source not found: $full_src - skipping"
        fi
    done
}

_install_tpm() {
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    
    if [[ ! -d "$tpm_dir" ]]; then
        log_info "Installing tmux plugin manager (tpm)..."
        safe_git_clone "https://github.com/tmux-plugins/tpm" "$tpm_dir" || return 1
        log_success "tpm installed successfully"
    else
        log_info "tpm already installed"
    fi
}

setup_dotfiles() {
    if [[ "$TOTAL_STEPS" -gt 1 ]]; then
        show_progress "Setting up dotfiles"
    fi
    
    _update_dotfiles_repo || return 1
    _init_submodules
    _create_symlinks
    _install_tpm
    
    return 0
}

update_dotfiles() {
    source "$SCRIPT_DIR/lib/validation.zsh"
    
    show_progress "Updating and re-linking dotfiles"
    
    if ! command_exists git; then
        log_error "Git is not installed"
        return 1
    fi
    
    setup_dotfiles || return 1
    
    log_success "Dotfiles updated"
    log_info "Restart your terminal or run 'source ~/.zshrc'"
}
