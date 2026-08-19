#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
export MOI_SOURCE="${MOI_SOURCE:-file://$repo_root}"

cd "$repo_root"
if [[ -x "$repo_root/target/debug/moi" ]]; then
  exec "$repo_root/target/debug/moi" plan "$@"
fi

exec cargo run --quiet -- plan "$@"
