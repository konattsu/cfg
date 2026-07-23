#!/usr/bin/env bash
set -euo pipefail

repo_url="${MOI_REPO_URL:-https://github.com/konattsu/moi.git}"
branch="${MOI_BRANCH:-main}"
self_url="${MOI_SELF_URL:-https://raw.githubusercontent.com/konattsu/moi/main/moi.sh}"
self_path="${MOI_SELF_PATH:-$HOME/.local/bin/moi}"

usage() {
  cat >&2 <<'EOF'
usage: moi [plan|apply] [options] [module ...]
EOF
}

self_update() {
  if [[ "${MOI_NO_SELF_UPDATE:-}" == "1" ]]; then
    return
  fi
  command -v curl >/dev/null 2>&1 || return

  local tmp
  tmp="$(mktemp)"
  if ! curl -fsSL "$self_url" -o "$tmp"; then
    rm -f "$tmp"
    return
  fi

  if [[ -f "$self_path" ]] && cmp -s "$tmp" "$self_path"; then
    rm -f "$tmp"
    return
  fi

  mkdir -p "$(dirname "$self_path")"
  install -m 755 "$tmp" "$self_path"
  rm -f "$tmp"

  if [[ "${MOI_REEXECED:-}" != "1" ]]; then
    MOI_REEXECED=1 exec "$self_path" "$@"
  fi
}

command_name="${1:-apply}"
case "$command_name" in
  plan|apply)
    shift || true
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    command_name="apply"
    ;;
esac

self_update "$command_name" "$@"

need_commands=()
command -v git >/dev/null 2>&1 || need_commands+=(git)
command -v python3 >/dev/null 2>&1 || need_commands+=(python3)

if ((${#need_commands[@]} > 0)); then
  echo "error: missing required commands: ${need_commands[*]}" >&2
  exit 1
fi

moi_dir="$(mktemp -d)"
trap 'rm -rf "$moi_dir"' EXIT

git clone --depth 1 --branch "$branch" "$repo_url" "$moi_dir"

exec "$moi_dir/scripts/$command_name.sh" "$@"
