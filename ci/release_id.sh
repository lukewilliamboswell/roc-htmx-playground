#!/usr/bin/env bash

set -euo pipefail

commit="${1:-HEAD}"
timestamp="$(TZ=UTC git show -s \
    --format=%cd \
    --date='format-local:%Y%m%dT%H%M%SZ' \
    "$commit")"
full_sha="$(git rev-parse "${commit}^{commit}")"
short_sha="${full_sha:0:12}"
release_id="${timestamp}-${short_sha}"

if ! printf '%s\n' "$release_id" |
    grep -Eq '^[0-9]{8}T[0-9]{6}Z-[0-9a-f]{12}$'
then
    echo "Could not derive a valid release ID from commit $commit." >&2
    exit 2
fi

printf '%s\n' "$release_id"
