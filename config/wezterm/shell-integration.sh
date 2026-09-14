#!/usr/bin/env bash

[[ $- == *i* && ${TERM_PROGRAM:-} == WezTerm ]] || return
command -v wezterm >/dev/null 2>&1 || return

_wezterm_cwd() {
  local status=$?
  command wezterm set-working-directory
  return "$status"
}

if [[ " ${PROMPT_COMMAND[*]-} " != *' _wezterm_cwd '* ]]; then
  PROMPT_COMMAND+=(_wezterm_cwd)
fi
