#!/usr/bin/env bash

[[ $- == *i* ]] || return

# Environment
export PATH="$HOME/.config/emacs/bin:$HOME/.local/bin:$PATH"
export NPM_CONFIG_PREFIX="$HOME/.local"
export GREP_COLORS='mt=1;36'
export EDITOR='nvim'
export VISUAL="$EDITOR"
export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"
export MANPAGER='nvim +Man!'
export PGPASSFILE="$HOME/.local/state/postgres/postgres-18/pgpass"
. "$HOME/.config/nnn/env"

# Aliases
alias sudo="doas"
alias sudoedit="doasedit"
alias ls='ls --color=auto --group-directories-first'
alias la='ls -lah --color=auto --group-directories-first'
alias lt='tree -C -a -L 2 --dirsfirst'
alias rm='trash'
alias c='clear'
alias ff='fastfetch && echo'
alias vim='nvim'
alias ..="echo 'cd ..'; cd .."
alias hl='rg --passthru'
alias n='nnn -e'
alias ga='git add'
alias gaa='git add --all'
alias gb='git branch'
alias gcl='git clone'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gc='git commit --verbose'
alias gcm='git commit -m'
alias gm='git merge'
alias gd='git diff'
alias gf='git fetch'
alias gl='git pull'
alias gp='git push'
alias gst='git status'
alias gss='git status --short'
alias gsw='git switch'
alias xup='doas xbps-install -Su'
alias xr='doas xbps-remove -R'
alias xro='doas xbps-remove -O'
alias xqo='xbps-query -o'

hf() {
  local selection
  selection=$(history | fzf --tac | sed 's/^[[:space:]]*[0-9]*[[:space:]]*//') || return
  printf '%s' "$selection" | xclip -selection clipboard
}

# Shell Options
shopt -s cdspell
shopt -s checkwinsize
shopt -s extglob
shopt -s autocd 2>/dev/null || true
shopt -s dirspell 2>/dev/null || true
shopt -s histappend
shopt -s cmdhist
shopt -s lithist
shopt -s progcomp_alias

eval "$(zoxide init bash)"

# Why is this on by default?
stty -ixon

# History
HISTFILE="$HOME/.bash_history"
HISTSIZE=50000
HISTFILESIZE=50000
HISTCONTROL=ignoreboth:erasedups

# Completion
bind 'set completion-ignore-case on'
bind 'set completion-map-case on'
bind 'set show-all-if-ambiguous on'

if [[ -r /usr/share/bash-completion/bash_completion ]]; then
  . /usr/share/bash-completion/bash_completion
fi

if declare -F _comp_command_offset >/dev/null; then
  _complete_doas() {
    # bash-completion reads and writes these locals through dynamic scope.
    local cur prev words cword comp_args
    _comp_initialize -- "$@" || return

    local i
    for ((i = 1; i < cword; i++)); do
      case ${words[i]} in
        -u | -C)
          if ((i + 1 == cword)); then
            if [[ ${words[i]} == -u ]]; then
              _comp_compgen -- -u
            else
              _comp_compgen_filedir
            fi
            return
          fi
          ((i++))
          ;;
        -s | -L) return ;;
        --)
          _comp_command_offset "$((i + 1))"
          return
          ;;
        -*) ;;
        *) break ;;
      esac
    done

    if ((i == cword)) && [[ $cur == -* ]]; then
      _comp_compgen -- -W '-C -L -n -s -u'
    else
      _comp_command_offset "$i"
    fi
  }
  complete -F _complete_doas doas

  # the default completion loader prevents bash's progcomp_alias fallback
  _complete_alias() {
    local expansion=${BASH_ALIASES[$1]}
    local -a expanded_words
    read -r -a expanded_words <<<"$expansion"

    local COMP_LINE=${COMP_LINE/"$1"/"$expansion"}
    local COMP_POINT=$((COMP_POINT + ${#expansion} - ${#1}))
    local COMP_CWORD=$((COMP_CWORD + ${#expanded_words[@]} - 1))
    local -a COMP_WORDS=("${expanded_words[@]}" "${COMP_WORDS[@]:1}")
    local words
    _comp_command_offset 0
  }

  for alias_name in "${!BASH_ALIASES[@]}"; do
    alias_expansion=${BASH_ALIASES[$alias_name]}
    # leave aliases containing shell syntax alone.
    if [[ $alias_expansion =~ ^[a-zA-Z0-9_./=[:space:]-]+$ &&
      ${alias_expansion%% *} != "$alias_name" ]]; then
      complete -o bashdefault -o default -F _complete_alias "$alias_name"
    fi
  done
  unset alias_name alias_expansion
fi

# fzf settings
export FZF_DEFAULT_OPTS="
  --color=fg:#B5A196
  --color=fg+:#E9D1C5
  --color=bg:#15110F
  --color=bg+:#34312d
  --color=hl:#C87546
  --color=hl+:#E8A64D
  --color=info:#B5A196
  --color=marker:#C87546
  --color=prompt:#C87546
  --color=spinner:#DC8853
  --color=pointer:#FFBD9B
  --color=header:#A45751
  --color=border:#B5A196
  --color=query:#E9D1C5
  --color=gutter:#15110F
  --highlight-line
  --info=inline-right
  --layout=reverse
  --pointer='█'
  --scrollbar='▌'
  --multi
  --border=top
"

# Prompt
git_prompt_segment() {
  local output line
  local branch=''
  local ahead=0
  local behind=0
  local dirty=0

  output=$(git status --porcelain=v2 --branch 2>/dev/null) || return

  while IFS= read -r line; do
    case $line in
      '# branch.head '*)
        branch=${line#'# branch.head '}
        ;;

      '# branch.ab '*)
        local ab=${line#'# branch.ab '}
        local a b
        read -r a b <<<"$ab"
        ahead=${a#+}
        behind=${b#-}
        ;;

      *)
        if [[ -n $line && $line != \#* && $line != \!* ]]; then
          dirty=1
        fi
        ;;
    esac
  done <<<"$output"

  if [[ $branch == '(detached)' ]]; then
    branch=$(git rev-parse --short HEAD 2>/dev/null) || return
  fi

  printf ' %s' "$branch"

  ((ahead > 0)) && printf ' ⇡%d' "$ahead"
  ((behind > 0)) && printf ' ⇣%d' "$behind"
  ((dirty)) && printf ' *'
  return 0
}

venv_prompt_name() {
  local key value

  [[ -r $VIRTUAL_ENV/pyvenv.cfg ]] || return 1

  while IFS='=' read -r key value; do
    key=${key//[[:space:]]/}

    if [[ $key == prompt ]]; then
      value=${value#"${value%%[![:space:]]*}"}
      value=${value%"${value##*[![:space:]]}"}

      printf '%s' "$value"
      return
    fi
  done <"$VIRTUAL_ENV/pyvenv.cfg"
}

make_prompt() {
  local status=$1
  local reset=$'\e[0m'
  local bold=$'\e[1m'
  local error=$'\e[38;2;164;87;81m'
  local primary=$'\e[38;2;241;162;120m'
  local secondary=$'\e[38;2;217;140;99m'
  local tertiary=$'\e[38;2;171;97;57m'
  local muted=$'\e[38;2;95;80;73m'
  local info=$'\e[38;2;148;77;36m'
  local host=$'\e[38;2;194;118;78m'
  local git_segment=''
  local status_segment=''
  local venv_segment=''
  local jobs_segment=''

  if _prompt_git_text=$(git_prompt_segment); then
    git_segment=" \[${tertiary}\]"'${_prompt_git_text}'"\[${reset}\]"
  fi

  if ((status != 0)); then
    status_segment=" \[${error}\] ${status}\[${reset}\]"
  fi

  if [[ -n ${VIRTUAL_ENV:-} ]]; then
    _prompt_venv_text=$(venv_prompt_name)
    [[ -n $_prompt_venv_text ]] || _prompt_venv_text=${VIRTUAL_ENV##*/}
    venv_segment=" \[${secondary}\] "'${_prompt_venv_text}'"\[${reset}\]"
  fi

  local job_count
  job_count=$(jobs -p | wc -l)

  if ((job_count > 0)); then
    jobs_segment=" \[${info}\]󱑞 ${job_count}\[${reset}\]"
  fi

  PS1="\[${primary}${bold}\]\w\[${reset}\]"
  PS1+="${git_segment}\[${reset}\]"
  PS1+="${venv_segment}"
  PS1+="${jobs_segment}"
  PS1+=" \[${muted}\]• \[${host}\]\h\[${reset}\]"
  PS1+="${status_segment}"
  PS1+="\n\[${secondary}${bold}\]❯\[${reset}\] "
}

_prompt_command() {
  local status=$?

  history -a
  history -n
  make_prompt "$status"

  return "$status"
}

if [[ " ${PROMPT_COMMAND[*]-} " != *' _prompt_command '* ]]; then
  PROMPT_COMMAND=(_prompt_command "${PROMPT_COMMAND[@]}")
fi
