#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: followup-debian.sh [--yes]

Assist manual follow-up tasks after running install.sh on Debian-based environments.

Options:
  -y, --yes   Select all follow-up sections.
  -h, --help  Show this help.

Without --yes, follow-up actions are prompted. When run as `curl ... | bash`,
prompts read from /dev/tty because stdin is the script body.
EOF
}

parse_args() {
  while (($# > 0)); do
    case "$1" in
      -y|--yes)
        yes=1
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "error: unknown option: $1" >&2
        usage >&2
        exit 2
        ;;
    esac
    shift
  done
}

source_common() {
  local script_dir common common_url tmp
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  common="$script_dir/followup-common.sh"
  common_url="https://raw.githubusercontent.com/konattsu/moi/main/scripts/followup-common.sh"
  if [[ -f "$common" ]]; then
    . "$common"
    return
  fi

  tmp="$(mktemp)"
  curl -fsSL "$common_url" -o "$tmp"
  . "$tmp"
  rm -f "$tmp"
}

source_common

main() {
  parse_args "$@"

  run_zsh_followup
  run_git_commit_key_followup
  run_docker_followup_debian
  run_gh_followup
  run_codex_followup
  show_keychain_followup
  show_manual_steps
  print_done
}

main "$@"
