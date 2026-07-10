#!/bin/bash

set -eo pipefail

_main() {
  _exec_in_container "${@}"

  echo
  cd "$(dirname "$0")" || exit 1
  INCLUDE_DIRS=$(awk '/^[[:space:]]*-.*modules\/zmk\/helpers\/include/ { print $NF }' draw/config.yaml)
  if ! ls ${INCLUDE_DIRS} 1>/dev/null ; then
    echo "ZMK keymap include dirs/files are missing."
    echo "Please initialize the build directory by building the firmware once:"
    echo "  ./build.sh"
    exit 1
  fi

  export PATH="${HOME}/.local/bin:${PATH}"

  if ! keymap --version &>/dev/null; then
    pip install --quiet --root-user-action=ignore --user keymap-drawer
  fi

  keymap -c draw/config.yaml parse -z config/kyria_rev3.keymap -b draw/keymap.yaml -c 12 -o /root/keymap.yaml
  keymap -c draw/config.yaml draw /root/keymap.yaml -o /app/draw/keymap.svg
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
      -v ./_keymap-drawer-pip-cache:/root/.cache/pip \
      python:3-slim \
      bash "/app/$(basename "$0")" "${@}"
    exit
  fi
}

_main "${@}"
