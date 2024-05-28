#!/bin/bash

set -o pipefail

_main() {
  _exec_in_container

  cd "$(dirname "$0")" || exit 1

  project_dir="$(realpath .)"
  base_dir="/_build/zmk-config"
  config_path="config"
  archive_name="firmware"
  zmk_load_arg=" -DZMK_EXTRA_MODULES='${project_dir}'"

  if [ "${base_dir}" != "${project_dir}" ]; then
    mkdir -p "${base_dir}/${config_path}"
    cp -R "${project_dir}/${config_path}"/* "${base_dir}/${config_path}/"
  fi

  cd "${base_dir}" || exit 1

  _west_prepare "${base_dir}" "${config_path}"
  _west_compile "${base_dir}" "${config_path}" nice_nano_v2 kyria_rev3_left
  _west_compile "${base_dir}" "${config_path}" nice_nano_v2 kyria_rev3_right

  echo
  ls -lh /_firmware
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
  local board="$3"
  local shield="$4"

  local build_dir="$(realpath "${base_dir}/../${board}-${shield}")"
  local artifacts_dir="/_firmware"
  local extra_cmake_args="-DSHIELD='${shield}'${zmk_load_arg}"
  local display_name="${shield} - ${board}"
  local artifact_name="${shield}-${board}-zmk.$(date +%F_%H%M%S)"

  mkdir -pv "${build_dir}" "${artifacts_dir}"
  west build -s zmk/app -d "${build_dir}" -b "${board}" -- -DZMK_CONFIG="${base_dir}/${config_path}" ${extra_cmake_args} ${cmake_args}

  cp "${build_dir}/zephyr/.config" "${artifacts_dir}/${artifact_name}.Kconfig"
  cp "${build_dir}/zephyr/zephyr.dts" "${artifacts_dir}/${artifact_name}.zephyr.dts"
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
    exec docker run --rm -it -v .:/app -v ./_build:/_build -v ./_firmware:/_firmware zmkfirmware/zmk-build-arm:stable "/app/$(basename "$0")"
    exit
  fi
}

_main "${@}"
