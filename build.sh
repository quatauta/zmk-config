#!/bin/bash

set -eo pipefail

_main() {
  _exec_in_container

  cd "$(dirname "$0")" || exit 1

  project_dir="$(realpath .)"
  base_dir="/_build/zmk-config"
  config_path="config"
  zmk_load_arg=" -DZMK_EXTRA_MODULES='${project_dir}'"
  local timestamp="$(date +%F_%H%M%S)"

  if [ "${base_dir}" != "${project_dir}" ]; then
    rm -rf "${base_dir}/${config_path}"/*
    mkdir -p "${base_dir}/${config_path}/"
    cp -R "${project_dir}/${config_path}"/* "${base_dir}/${config_path}/"
  fi

  cd "${base_dir}" || exit 1

  _west_prepare "${base_dir}" "${config_path}"

  grep -v '^\s*#' "${project_dir}/build.yaml" |
  awk -vRS='  - ' '/board:/ { print $2, $4 }' |
  while read -r board shield ; do
    _west_compile "${base_dir}" "${config_path}" "${timestamp}" "${board}" "${shield}"
  done

  echo
  echo "_firmware/${timestamp}/"
  ls -lh "/_firmware/${timestamp}"
}

_west_prepare() {
  local base_dir="$1"
  local config_path="$2"

  [[ -d .west ]] || west init -l "${base_dir}/${config_path}"
  west update
  west zephyr-export
}

_west_compile() {
  local base_dir="$1"
  local config_path="$2"
  local timestamp="$3"
  local board="$4"
  local shield="$5"

  local build_dir="$(realpath "${base_dir}/../${board}-${shield}")"
  local extra_cmake_args="-DSHIELD='${shield}'${zmk_load_arg}"
  local display_name="${shield} - ${board}"
  local artifacts_dir="/_firmware/${timestamp}"
  local artifact_name="zmk.${timestamp}.${board}.${shield}"

  mkdir -pv "${build_dir}" "${artifacts_dir}"
  west build -s zmk/app -d "${build_dir}" -b "${board}" -- -DZMK_CONFIG="${base_dir}/${config_path}" ${extra_cmake_args} ${cmake_args}

  # cp "${build_dir}/zephyr/.config" "${artifacts_dir}/${artifact_name}.Kconfig"
  # cp "${build_dir}/zephyr/zephyr.dts" "${artifacts_dir}/${artifact_name}.zephyr.dts"
  cp "${build_dir}/zephyr/zmk.uf2" "${artifacts_dir}/${artifact_name}.uf2"
}

_start_container_runtime() {
  for RUNTIME in orbctl /Applications/{OrbStack,Docker}.app ; do
    command -v "${RUNTIME}" && break
    [[ -d "${RUNTIME}" ]] && break
  done

  case "${RUNTIME}" in
    *.app )
      open -a "${RUNTIME}"
      ;;
    * )
      "${RUNTIME}" start
      ;;
  esac
}

_exec_in_container() {
  if [[ ! -f /.dockerenv ]] ; then
    _start_container_runtime
    exec docker run --rm -it --pull=always \
      -v .:/app:ro \
      -v ./_build:/_build \
      -v ./_firmware:/_firmware \
      zmkfirmware/zmk-build-arm:stable \
      "/app/$(basename "$0")"
    exit
  fi
}

_main "${@}"
