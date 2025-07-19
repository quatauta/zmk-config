#!/bin/bash

set -eo pipefail

_main() {
  _exec_in_container "${@}"

  echo
  cd "$(dirname "$0")" || exit 1
  export PATH="${PATH}:${HOME}/.local/bin"

  INCLUDE_DIRS=$(awk '/^[[:space:]]*-.*modules\/zmk\/helpers\/include/ { print $NF }' draw/config.yaml)
  if ! ls ${INCLUDE_DIRS} 1>/dev/null ; then
    echo "ZMK keymap include dirs/files are missing."
    echo "Please initialize the build directory by building the firmware once:"
    echo "  ./build.sh"
    exit 1
  fi

  export DEBIAN_FRONTEND=noninteractive
  rm -f /etc/apt/apt.conf.d/docker-clean
  set -x
  apt-get -qq -y update                   &>/dev/null
  apt-get -qq -y upgrade                  &>/dev/null
  apt-get -qq -y install python3-dev pipx &>/dev/null
  mkdir -p "${HOME}/.local/bin"
  pipx install --quiet keymap-drawer

  "${HOME}/.local/bin/keymap" -c draw/config.yaml parse -z config/kyria_rev3.keymap -b draw/keymap.yaml -c 12 -o /root/keymap.yaml
  "${HOME}/.local/bin/keymap" -c draw/config.yaml draw /root/keymap.yaml -o /app/draw/keymap.svg
}

_start_container_runtime() {
  for RUNTIME in orbctl /Applications/{OrbStack,Docker}.app; do
    command -v "${RUNTIME}" &>/dev/null && break
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
    exec docker run -q --rm -it --pull=always \
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
