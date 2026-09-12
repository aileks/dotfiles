#!/usr/bin/env bash

[[ $- == *i* && ${TERM_PROGRAM:-} == WezTerm ]] || return

_wezterm_prompt() {
  local status=$? title=${PWD##*/}
  [[ $PWD == "$HOME" ]] && title='~'
  [[ $PWD == / ]] && title=/

  # OSC 0 reaches pane, tab, and window titles, including over the mux.
  printf '\033]0;%s\007' "${title//[[:cntrl:]]/}"
  wezterm set-working-directory
  return "$status"
}

# Run after system prompt hooks, which may also set the title.
if [[ " ${PROMPT_COMMAND[*]} " != *' _wezterm_prompt '* ]]; then
  PROMPT_COMMAND+=(_wezterm_prompt)
fi
