#!/bin/bash

set -e
set -o pipefail
set -u

THIS_PATH="$(readlink --canonicalize-existing "${0}")"
THIS_NAME="$(basename "${THIS_PATH}")"
THIS_DIR="$(dirname "${THIS_PATH}")"

mkdir --parents                  \
    "${THIS_DIR}/.volume/backup" \
    "${THIS_DIR}/.volume/config" \
    "${THIS_DIR}/.volume/data"

exec docker run                                                                     \
    --interactive=true                                                              \
    --mount type=bind,source="/etc/localtime",destination="/etc/localtime",readonly \
    --mount type=bind,source="/etc/timezone",destination="/etc/timezone",readonly   \
    --mount type=tmpfs,destination="/run"                                           \
    --mount type=tmpfs,destination="/tmp"                                           \
    --mount type=bind,source="${THIS_DIR}/.volume/backup",destination="/backup"     \
    --mount type=bind,source="${THIS_DIR}/.volume/config",destination="/config"     \
    --mount type=bind,source="${THIS_DIR}/.volume/data",destination="/data"         \
    --read-only                                                                     \
    --rm                                                                            \
    --tty=true                                                                      \
    shadowhunt/base
