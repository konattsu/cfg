#!/usr/bin/env bash
set -euo pipefail

repo_url="${CFG_REPO_URL:-https://github.com/konattsu/cfg.git}"
branch="${CFG_BRANCH:-main}"
cfg_dir="${CFG_DIR:-$HOME/.local/share/cfg}"
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

if [[ -e "$cfg_dir" && ! -d "$cfg_dir/.git" ]]; then
  echo "error: CFG_DIR exists but is not a git repository: $cfg_dir" >&2
  exit 1
fi

if [[ ! -d "$cfg_dir/.git" ]]; then
  mkdir -p "$(dirname "$cfg_dir")"
  git clone --depth 1 --branch "$branch" "$repo_url" "$cfg_dir"
else
  git -C "$cfg_dir" fetch --depth 1 origin "$branch:refs/remotes/origin/$branch"
  current_branch="$(git -C "$cfg_dir" rev-parse --abbrev-ref HEAD)"
  if [[ "$current_branch" != "$branch" ]]; then
    if git -C "$cfg_dir" show-ref --verify --quiet "refs/heads/$branch"; then
      git -C "$cfg_dir" switch "$branch"
    else
      git -C "$cfg_dir" switch --track "origin/$branch"
    fi
  fi
  git -C "$cfg_dir" pull --ff-only --depth 1 origin "$branch"
fi

exec "$cfg_dir/scripts/$command.sh" "$@"
