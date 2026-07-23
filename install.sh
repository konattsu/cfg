#!/usr/bin/env bash
set -euo pipefail

repo_url="${CFG_REPO_URL:-https://github.com/konattsu/cfg.git}"
branch="${CFG_BRANCH:-main}"
command="${CFG_COMMAND:-apply}"

case "$command" in
  plan|apply) ;;
  *)
    echo "error: CFG_COMMAND must be 'plan' or 'apply'" >&2
    exit 2
    ;;
esac

need_commands=()
command -v git >/dev/null 2>&1 || need_commands+=(git)
command -v python3 >/dev/null 2>&1 || need_commands+=(python3)

if ((${#need_commands[@]} > 0)); then
  echo "error: missing required commands: ${need_commands[*]}" >&2
  exit 1
fi

cfg_dir="$(mktemp -d)"
trap 'rm -rf "$cfg_dir"' EXIT

git clone --depth 1 --branch "$branch" "$repo_url" "$cfg_dir"

"$cfg_dir/scripts/$command.sh" "$@"
