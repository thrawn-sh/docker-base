#!/bin/bash

set -e
set -o pipefail
set -u

THIS_PATH="$(readlink --canonicalize-existing "${0}")"
THIS_NAME="$(basename "${THIS_PATH}")"
THIS_DIR="$(dirname "${THIS_PATH}")"

exec docker run                                                                     \
    --interactive=true                                                              \
    --mount type=bind,source="/etc/localtime",destination="/etc/localtime",readonly \
    --mount type=bind,source="/etc/timezone",destination="/etc/timezone",readonly   \
    --mount type=tmpfs,destination="/run"                                           \
    --mount type=tmpfs,destination="/tmp"                                           \
    --read-only                                                                     \
    --rm                                                                            \
    --tty=true                                                                      \
    shadowhunt/base
