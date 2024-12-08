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
    (
      awk -vFS='[ "]+' '/#include "zmk-helpers/ { print $2 }' config/kyria_rev3.keymap |
      xargs -rt -I HELPER cat _build/zmk-config/modules/helpers/include/HELPER
      cat config/mouse.dtsi
      cat config/kyria_rev3.keymap
      cat config/combos.dtsi
    ) > /root/keymap
    "${HOME}/.local/bin/keymap" -c keymap-drawer.config.yaml parse -b keymap-drawer.keymap.yaml -c 12 -z /root/keymap -o /root/keymap.yaml
    (
      echo "layout:"
      echo "  qmk_keyboard: splitkb/kyria/rev3"
      echo "  qmk_layout: LAYOUT_split_3x6_5"
      cat /root/keymap.yaml
    ) > /root/keymap2.yaml
    "${HOME}/.local/bin/keymap" -c keymap-drawer.config.yaml draw -o /app/keymap.svg /root/keymap2.yaml
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
      -v .:/app \
      -v ./_keymap-drawer:/root \
      -v ./_keymap-drawer-apk-cache:/etc/apk/cache \
      alpine:latest \
      sh "/app/$(basename "$0")" "${@}"
    exit
  fi
}

_main "${@}"
