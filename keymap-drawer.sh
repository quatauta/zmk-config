#!/bin/bash

set -eo pipefail

_main() {
  _exec_in_container "${@}"

  cd "$(dirname "$0")" || exit 1
  export PATH="${PATH}:${HOME}/.local/bin"

  set -x
  apk add --quiet pipx
  mkdir -p "${HOME}/.local/bin"
  pipx install --quiet keymap-drawer

  if [[ $# -gt 0 ]]; then
    "${HOME}/.local/bin/keymap" "${@}" # -c keymap-drawer.config.yaml draw keymap-drawer.keymap.yaml
  else
    "${HOME}/.local/bin/keymap" -c keymap-drawer.config.yaml draw -o /root/keymap.svg keymap-drawer.keymap.yaml
  fi
}

_start_container_runtime() {
  for RUNTIME in orbctl /Applications/{OrbStack,Docker}.app; do
    command -v "${RUNTIME}" && break
    [[ -d "${RUNTIME}" ]] && break
  done

  case "${RUNTIME}" in
  *.app)
    open -a "${RUNTIME}"
    ;;
  *)
    "${RUNTIME}" start
    ;;
  esac
}

_exec_in_container() {
  if [[ ! -f /.dockerenv ]]; then
    _start_container_runtime
    exec docker run --rm -it --pull=always \
      -v .:/app:ro \
      -v ./_keymap-drawer:/root \
      -v ./_keymap-drawer-apk-cache:/etc/apk/cache \
      alpine:latest \
      sh "/app/$(basename "$0")" "${@}"
    exit
  fi
}

_main "${@}"
