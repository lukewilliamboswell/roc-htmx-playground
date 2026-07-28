#!/usr/bin/env bash

set -euo pipefail

if rg -n \
    'attribute\("class"|Attribute\.attribute\("class"|class\("' \
    src \
    --glob '!Design.roc'
then
    echo "Tailwind class declarations must live in src/Design.roc." >&2
    exit 1
fi

echo "source contracts: ok"
