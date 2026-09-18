#!/usr/bin/bash
set -euo 'pipefail'
shopt -s 'nullglob'

(
    cd "$(mktemp -d)" || exit 1
    git clone "https://github.com/bjpop/gurita"
    python3 -m pip install --upgrade "./gurita"
    rm -rf gurita
)
