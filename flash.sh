#!/bin/bash

set -eo pipefail

FIRMWARE_DIR="${1:?Please provide the directory with the keyboard firmware}"

FIRMWARE_LEFT="$(find "${FIRMWARE_DIR}/" -name "*_left.uf2" | head -n1)"
FIRMWARE_RIGHT="$(find "${FIRMWARE_DIR}/" -name "*_right.uf2" | head -n1)"

VOLUME_LEFT="/Volumes/NICENA_L"
VOLUME_RIGHT="/Volumes/NICENA_R"
CURRENT="CURRENT.UF2"

if [[ -r "${VOLUME_LEFT}/${CURRENT}" ]] ; then
  ( cp -v "${FIRMWARE_LEFT}" "${VOLUME_LEFT}/" ) &
else
  echo "${VOLUME_LEFT}/${CURRENT} does not exist"
fi

if [[ -r "${VOLUME_RIGHT}/${CURRENT}" ]] ; then
  ( cp -v "${FIRMWARE_RIGHT}" "${VOLUME_RIGHT}/" ) &
else
  echo "${VOLUME_RIGHT}/${CURRENT} does not exist"
fi

wait
