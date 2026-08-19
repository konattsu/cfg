#!/usr/bin/env bash
set -euo pipefail

repo="${MOI_GITHUB_REPOSITORY:-konattsu/moi}"
self_path="${MOI_SELF_PATH:-$HOME/.local/bin/moi}"

usage() {
  cat >&2 <<'EOF'
usage: curl -fsSL https://raw.githubusercontent.com/konattsu/moi/main/install.sh | bash -s -- [global options] plan|apply [options] [module ...]
EOF
}

target_triple() {
  local os arch
  os="$(uname -s)"
  arch="$(uname -m)"

  case "$os" in
    Linux) ;;
    *)
      echo "error: unsupported os: $os" >&2
      exit 1
      ;;
  esac

  case "$arch" in
    x86_64|amd64) echo "x86_64-unknown-linux-gnu" ;;
    aarch64|arm64) echo "aarch64-unknown-linux-gnu" ;;
    *)
      echo "error: unsupported architecture: $arch" >&2
      exit 1
      ;;
  esac
}

if (($# == 0)); then
  usage
  exit 1
fi

command -v curl >/dev/null 2>&1 || {
  echo "error: missing required command: curl" >&2
  exit 1
}

target="$(target_triple)"
asset="${MOI_RELEASE_ASSET:-moi-$target}"
release_base="${MOI_RELEASE_BASE:-https://github.com/$repo/releases/latest/download}"
url="$release_base/$asset"

mkdir -p "$(dirname "$self_path")"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

curl -fsSL "$url" -o "$tmp"
install -m 755 "$tmp" "$self_path"

MOI_FIRST_INSTALL=1 exec "$self_path" "$@"
