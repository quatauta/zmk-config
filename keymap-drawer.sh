#!/bin/bash

set -eo pipefail

_main() {
  _exec_in_container "${@}"

  cd "$(dirname "$0")" || exit 1
  export PATH="${PATH}:${HOME}/.local/bin"

  set -x
  export DEBIAN_FRONTEND=noninteractive
  rm -f /etc/apt/apt.conf.d/docker-clean
  apt-get -qq -y update                   &>/dev/null
  # apt-get -qq -y upgrade                  &>/dev/null
  apt-get -qq -y install python3-dev pipx &>/dev/null
  mkdir -p "${HOME}/.local/bin"
  pipx install --quiet keymap-drawer

  if [[ $# -gt 0 ]]; then
    "${HOME}/.local/bin/keymap" "${@}" # -c keymap-drawer.config.yaml draw keymap-drawer.keymap.yaml
  else
    "${HOME}/.local/bin/keymap" -c keymap-drawer.config.yaml parse -z config/kyria_rev3.keymap -b keymap-drawer.keymap.yaml -c 12 -o /root/keymap.yaml
    "${HOME}/.local/bin/keymap" -c keymap-drawer.config.yaml draw /root/keymap.yaml -o /app/keymap.svg
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
      -v ./_keymap-drawer-apt-cache:/var/cache/apt \
      -v ./_keymap-drawer-apt-lib:/var/lib/apt \
      ubuntu:latest \
      bash "/app/$(basename "$0")" "${@}"
    exit
  fi
}

_main "${@}"
