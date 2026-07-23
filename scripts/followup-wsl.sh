#!/usr/bin/env bash
set -euo pipefail

yes=0
git_commit_key="$HOME/.ssh/git_commit"
allowed_signers="$HOME/.ssh/allowed_signers"
git_user_name="konattsu"
git_user_email="139730998+konattsu@users.noreply.github.com"

usage() {
  cat <<'EOF'
Usage: followup-wsl.sh [--yes]

Assist manual follow-up tasks after running install.sh on disposable WSL environments.

Options:
  -y, --yes   Select all follow-up sections without confirmation.
  -h, --help  Show this help.
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

section() {
  printf '\n==> %s\n' "$1"
}

confirm() {
  local prompt="$1"
  local answer

  if ((yes)); then
    return 0
  fi

  printf "%s [y/N] " "$prompt"
  read -r answer
  [[ "$answer" == "y" || "$answer" == "Y" ]]
}

git_email() {
  git config --global --get user.email 2>/dev/null || printf '%s\n' "$git_user_email"
}

ensure_allowed_signer() {
  local pub_key="$git_commit_key.pub"
  local principal key_type key_body key_comment

  [[ -f "$pub_key" ]] || return

  principal="$(git_email)"
  [[ -n "$principal" ]] || principal="${USER:-user}@$(hostname)"

  read -r key_type key_body key_comment <"$pub_key"
  touch "$allowed_signers"
  if awk -v key_type="$key_type" -v key_body="$key_body" '$2 == key_type && $3 == key_body { found = 1 } END { exit !found }' "$allowed_signers"; then
    chmod 644 "$allowed_signers"
    return
  fi

  printf '%s %s %s' "$principal" "$key_type" "$key_body" >>"$allowed_signers"
  if [[ -n "${key_comment:-}" ]]; then
    printf ' %s' "$key_comment" >>"$allowed_signers"
  fi
  printf '\n' >>"$allowed_signers"
  chmod 644 "$allowed_signers"
}

run_zsh_followup() {
  section "zsh"

  if [[ "${SHELL:-}" == "/bin/zsh" ]]; then
    echo "ok: default shell already appears to be /bin/zsh."
    return
  fi

  if confirm "Run chsh -s /bin/zsh?"; then
    chsh -s /bin/zsh
    echo "done: restart the WSL session for the shell change to take effect."
  else
    echo "skip: zsh default shell unchanged."
  fi
}

run_git_commit_key_followup() {
  section "git commit SSH key"

  if [[ ! -f "$git_commit_key" ]]; then
    if confirm "Generate ed25519 SSH key at $git_commit_key?"; then
      local email
      email="$(git_email)"
      [[ -n "$email" ]] || email="${USER:-user}@$(hostname)"
      ssh-keygen -t ed25519 -C "$email" -f "$git_commit_key"
    else
      echo "skip: SSH key generation skipped."
      return
    fi
  else
    echo "ok: found $git_commit_key."
  fi

  if [[ -f "$git_commit_key.pub" ]]; then
    ensure_allowed_signer
    echo "done: ensured allowed signer in $allowed_signers."

    git config --global user.name "$git_user_name"
    git config --global user.email "$git_user_email"
    git config --global user.signingkey "$git_commit_key.pub"
    git config --global gpg.format ssh
    git config --global gpg.ssh.allowedSignersFile "$allowed_signers"
    git config --global commit.gpgsign true
    echo "done: configured git SSH commit signing."

    echo
    echo "Public key to register with GitHub:"
    cat "$git_commit_key.pub"
  else
    echo "skip: public key not found: $git_commit_key.pub"
  fi
}

show_keychain_followup() {
  section "keychain"

  cat <<'EOF'
Put local keychain settings in ~/.config/cfg/keychain.local.sh if you want keychain to load specific SSH keys.
EOF

  if [[ -f "$git_commit_key" ]]; then
    echo
    echo "Example:"
    echo "  eval \"\$(keychain --eval $git_commit_key)\""
    return
  fi

  echo
  echo "No git_commit key found. Files under ~/.ssh:"
  if [[ ! -d "$HOME/.ssh" ]]; then
    echo "  (none: ~/.ssh does not exist)"
    return
  fi

  shopt -s nullglob
  local files=("$HOME"/.ssh/*)
  shopt -u nullglob

  if ((${#files[@]} == 0)); then
    echo "  (none)"
    return
  fi

  local file
  for file in "${files[@]}"; do
    [[ -f "$file" ]] || continue
    echo "  - ${file##*/}"
  done
}

run_docker_followup() {
  section "docker"

  if id -nG | tr ' ' '\n' | grep -qx docker; then
    echo "ok: current user is already in the docker group."
    return
  fi

  if confirm "Run sudo usermod -aG docker ${USER:-$(id -un)}?"; then
    sudo usermod -aG docker "${USER:-$(id -un)}"
    echo "done: restart the WSL session for the docker group change to take effect."
  else
    echo "skip: docker group unchanged."
  fi
}

run_gh_followup() {
  section "GitHub CLI"

  if gh auth status --hostname github.com >/dev/null 2>&1; then
    echo "ok: gh is already authenticated for github.com."
    return
  fi

  if confirm "Run gh auth login?"; then
    gh auth login
  else
    echo "skip: gh auth login not run."
  fi
}

main() {
  parse_args "$@"

  run_zsh_followup
  run_git_commit_key_followup
  run_docker_followup
  run_gh_followup
  show_keychain_followup

  section "done"
  echo "If chsh or docker group membership changed, restart the WSL session."
}

main "$@"
