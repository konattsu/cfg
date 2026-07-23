#!/usr/bin/env bash
set -euo pipefail

self_url="${MOI_SELF_URL:-https://raw.githubusercontent.com/konattsu/moi/main/moi.sh}"
self_path="${MOI_SELF_PATH:-$HOME/.local/bin/moi}"

command -v curl >/dev/null 2>&1 || {
  echo "error: missing required command: curl" >&2
  exit 1
}

mkdir -p "$(dirname "$self_path")"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

curl -fsSL "$self_url" -o "$tmp"
install -m 755 "$tmp" "$self_path"

exec "$self_path" "$@"
