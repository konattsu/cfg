#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "error: followup-common.sh is a shared library; run followup-debian.sh or followup-arch.sh instead." >&2
  exit 1
fi

yes=0
git_commit_key="$HOME/.ssh/git_commit"
allowed_signers="$HOME/.ssh/allowed_signers"
keychain_local="$HOME/.config/moi/keychain.local.sh"
git_user_name="konattsu"
git_user_email="139730998+konattsu@users.noreply.github.com"
manual_steps=()

section() {
  printf '\n==> %s\n' "$1"
}

confirm() {
  local prompt="$1"
  local answer

  if ((yes)); then
    return 0
  fi

  if [[ ! -r /dev/tty ]]; then
    echo "decline: $prompt (/dev/tty is not available; use --yes to run)"
    return 1
  fi

  printf "%s [y/N] " "$prompt" > /dev/tty
  read -r answer < /dev/tty
  [[ "$answer" == "y" || "$answer" == "Y" ]]
}

add_manual_step() {
  manual_steps+=("$1")
}

user_at_machine() {
  local user machine
  user="${USER:-$(id -un 2>/dev/null || printf user)}"
  machine="$(hostname -s 2>/dev/null || hostname 2>/dev/null || printf machine)"
  printf '%s@%s\n' "$user" "$machine"
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

  if [[ -n "$key_comment" ]]; then
    printf '%s %s %s %s\n' "$principal" "$key_type" "$key_body" "$key_comment" >>"$allowed_signers"
  else
    printf '%s %s %s\n' "$principal" "$key_type" "$key_body" >>"$allowed_signers"
  fi
  chmod 644 "$allowed_signers"
}

ensure_keychain_local_git_commit() {
  local line

  [[ -f "$git_commit_key" ]] || return

  line="eval \"\$(keychain --eval $git_commit_key)\""
  mkdir -p "$(dirname "$keychain_local")"
  touch "$keychain_local"

  if grep -Fxq "$line" "$keychain_local"; then
    echo "ok: $git_commit_key is already listed in $keychain_local."
  else
    printf '%s\n' "$line" >>"$keychain_local"
    echo "done: added $git_commit_key to $keychain_local."
  fi

  if command -v keychain >/dev/null 2>&1; then
    eval "$(keychain --eval "$git_commit_key")"
    echo "done: loaded $git_commit_key with keychain."
  else
    echo "skip: keychain command not found."
  fi
}

run_zsh_followup() {
  section "zsh"

  if [[ "${SHELL:-}" == "/bin/zsh" ]]; then
    echo "ok: default shell already appears to be /bin/zsh."
    return
  fi

  add_manual_step "Run \`chsh -s /bin/zsh\`, then restart the login session."
  echo "manual: default shell change is left for the final follow-up."
}

run_git_commit_key_followup() {
  section "git commit SSH key"

  if ! confirm "Configure git commit SSH key, allowed_signers, git signing, and keychain?"; then
    echo "skip: git commit SSH key follow-up skipped."
    return
  fi

  if [[ ! -f "$git_commit_key" ]]; then
    local comment
    comment="$(user_at_machine)"
    ssh-keygen -t ed25519 -C "$comment" -f "$git_commit_key"
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

  ensure_keychain_local_git_commit
}

show_keychain_followup() {
  section "keychain"

  cat <<'EOF'
Put local keychain settings in ~/.config/moi/keychain.local.sh if you want keychain to load specific SSH keys.
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

run_docker_group_followup() {
  if id -nG | tr ' ' '\n' | grep -qx docker; then
    echo "ok: current user is already in the docker group."
    return
  fi

  if confirm "Run sudo usermod -aG docker ${USER:-$(id -un)}?"; then
    sudo usermod -aG docker "${USER:-$(id -un)}"
    echo "done: restart the login session for the docker group change to take effect."
  else
    echo "skip: docker group unchanged."
  fi
}

run_docker_followup_debian() {
  section "docker"
  run_docker_group_followup
}

run_docker_followup_arch() {
  section "docker"

  if command -v systemctl >/dev/null 2>&1; then
    if systemctl is-enabled --quiet docker.service 2>/dev/null && systemctl is-active --quiet docker.service 2>/dev/null; then
      echo "ok: docker.service is enabled and active."
    elif confirm "Run sudo systemctl enable --now docker.service?"; then
      sudo systemctl enable --now docker.service
      echo "done: enabled and started docker.service."
    else
      echo "skip: docker.service unchanged."
      add_manual_step "Run \`sudo systemctl enable --now docker.service\` if Docker should start automatically."
    fi
  else
    echo "manual: systemctl command not found."
    add_manual_step "Enable and start docker.service if this Arch environment uses systemd."
  fi

  run_docker_group_followup
}

run_gh_followup() {
  section "GitHub CLI"
  local ran_login=0

  if ! command -v gh >/dev/null 2>&1; then
    echo "skip: gh command not found."
    add_manual_step "After installing GitHub CLI, run \`gh auth login\` and then \`gh auth setup-git\`."
    return
  fi

  if gh auth status --hostname github.com >/dev/null 2>&1; then
    echo "ok: gh is already authenticated for github.com."
  elif confirm "Run gh auth login?"; then
    gh auth login
    ran_login=1
  fi

  if ((ran_login)) && gh auth status --hostname github.com >/dev/null 2>&1; then
    if confirm "Run gh auth setup-git?"; then
      gh auth setup-git
    else
      echo "skip: gh auth setup-git not run."
    fi
  elif ((ran_login)); then
    echo "skip: gh auth setup-git requires gh authentication."
  else
    echo "skip: gh auth setup-git not needed."
  fi
}

run_codex_followup() {
  section "Codex"

  if ! command -v codex >/dev/null 2>&1; then
    add_manual_step "After installing Codex, run \`codex\` in an interactive shell and complete login."
    echo "manual: codex command not found yet."
    return
  fi

  add_manual_step "Run \`codex\` in an interactive shell and complete login."
  echo "manual: Codex login is left for the final follow-up."
}

show_manual_steps() {
  section "manual follow-up"

  if ((${#manual_steps[@]} == 0)); then
    echo "No manual steps remain."
    return
  fi

  local step
  for step in "${manual_steps[@]}"; do
    echo "- $step"
  done
}

print_done() {
  section "done"
  echo "If the default shell or docker group membership changed, restart the login session."
}
