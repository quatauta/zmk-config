#!/bin/bash

if [[ ! -f /.dockerenv ]] ; then
  exec docker run --rm -it -v .:/app -v ./work:/work zmkfirmware/zmk-build-arm:stable "/app/$(basename "$0")"
fi

set -o pipefail

_main() {
  cd "$(dirname "$0")" || exit 1

  project_dir="$(realpath .)"
  base_dir="/work/zmk-config"
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
  ls -lh /work/artifacts/
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

  local build_dir="/work/${board}-${shield}"
  #local zephyr_version="${ZEPHYR_VERSION}"
  local extra_cmake_args="-DSHIELD='${shield}'${zmk_load_arg}"
  local display_name="${shield} - ${board}"
  local artifact_name="${shield}-${board}-zmk"
  local artifacts_dir="$(realpath "${build_dir}/../artifacts")"

  mkdir -pv "${build_dir}" "${artifacts_dir}"
  west build -s zmk/app -d "${build_dir}" -b "${board}" -- -DZMK_CONFIG="${base_dir}/${config_path}" ${extra_cmake_args} ${cmake_args}

  cp "${build_dir}/zephyr/.config" "${artifacts_dir}/${artifact_name}.Kconfig"
  cp "${build_dir}/zephyr/zephyr.dts" "${artifacts_dir}/${artifact_name}.zephyr.dts"
  cp "${build_dir}/zephyr/zmk.uf2" "${artifacts_dir}/${artifact_name}.uf2"
}

_main "${@}"
