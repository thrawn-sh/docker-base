#!/bin/bash

set -e
set -o pipefail
set -u

THIS_PATH="$(readlink --canonicalize-existing "${0}")"
THIS_NAME="$(basename "${THIS_PATH}")"
THIS_DIR="$(dirname "${THIS_PATH}")"

mkdir --parents                  \
    "${THIS_DIR}/.volume/backup" \
    "${THIS_DIR}/.volume/config"

exec docker run                                                                          \
    --mount type=bind,source="/etc/localtime",destination="/etc/localtime",readonly      \
    --mount type=bind,source="/etc/timezone",destination="/etc/timezone",readonly        \
    --mount type=tmpfs,destination="/run"                                                \
    --mount type=tmpfs,destination="/tmp"                                                \
    --mount type=bind,source="${THIS_DIR}/.volume/backup",destination="/backup"          \
    --mount type=bind,source="${THIS_DIR}/.volume/config",destination="/config",readonly \
    --read-only                                                                          \
    --rm                                                                                 \
    shadowhunt/base
