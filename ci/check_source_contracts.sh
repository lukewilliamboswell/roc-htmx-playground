#!/usr/bin/env bash

set -euo pipefail

if grep -R -n -E \
    --include='*.roc' \
    --exclude='Design.roc' \
    'attribute\("class"|Attribute\.attribute\("class"|class\("' \
    src
then
    echo "Tailwind class declarations must live in src/Design.roc." >&2
    exit 1
fi

echo "source contracts: ok"
