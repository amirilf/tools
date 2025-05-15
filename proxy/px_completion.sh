#!/bin/bash
_px_complete() {
  local cur profiles
  cur="${COMP_WORDS[COMP_CWORD]}"
  profiles=$(grep -oP '(?<=\[)[^]]+' "{the config file path}" | tr '\n' ' ')
  if [[ ${COMP_CWORD} -eq 1 ]]; then
    COMPREPLY=( $(compgen -W "${profiles}" -- "${cur}") )
  fi
}
complete -F _px_complete px