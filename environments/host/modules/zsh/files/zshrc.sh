# --- interactive only ---
[[ -o interactive ]] || return

# --- Oh My Zsh ---
export ZSH="$HOME/.oh-my-zsh"

fpath=("$HOME/.local/share/zsh/site-functions" $fpath)

plugins=(
  git
  zsh-syntax-highlighting
  zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

ZSH_HIGHLIGHT_STYLES[precommand]='fg=#FFE673,bold,underline'

ZSH_HIGHLIGHT_STYLES[command]='fg=#4BB3CE'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#4BB3CE'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#4BB3CE'
ZSH_HIGHLIGHT_STYLES[function]='fg=#4BB3CE'

ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#D0669A'

ZSH_HIGHLIGHT_STYLES[single-quoted-argument-unclosed]='fg=#FFC6E2'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument-unclosed]='fg=#FFC6E2'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument-unclosed]='fg=#FFC6E2'

ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#D8E9FC'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#D8E9FC'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#D8E9FC'

ZSH_HIGHLIGHT_STYLES[globbing]='fg=#92F3A4'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=#92F3A4'

# --- Prompt (oh-my-posh) ---
export PATH="$HOME/.local/bin:$PATH"

# Identify the distro from within the running environment.
unset POSH_DISTRO_ID POSH_DISTRO_ID_SYMBOL
if [[ -r /etc/os-release ]]; then
  POSH_OS_RELEASE_ID="$(. /etc/os-release 2>/dev/null; printf '%s' "${ID:-}")"
  POSH_OS_RELEASE_ID_LIKE="$(. /etc/os-release 2>/dev/null; printf '%s' "${ID_LIKE:-}")"
  case "$POSH_OS_RELEASE_ID" in
    arch)
      export POSH_DISTRO_ID=arch
      export POSH_DISTRO_ID_SYMBOL=a
      ;;
    debian)
      export POSH_DISTRO_ID=debian
      export POSH_DISTRO_ID_SYMBOL=d
      ;;
    *)
      if [[ " $POSH_OS_RELEASE_ID_LIKE " == *" debian "* ]]; then
        export POSH_DISTRO_ID=debian
        export POSH_DISTRO_ID_SYMBOL=d
      else
        unset POSH_DISTRO_ID
        export POSH_DISTRO_ID_SYMBOL=.
      fi
      ;;
  esac
  unset POSH_OS_RELEASE_ID POSH_OS_RELEASE_ID_LIKE
else
  export POSH_DISTRO_ID_SYMBOL=.
fi

unset POSH_CONTAINER_KIND POSH_CONTAINER_KIND_SYMBOL
# Add other verified runtimes here when needed, for example: podman, lxc, systemd-nspawn.
if [[ -f /.dockerenv ]] || grep -qa 'docker' /proc/1/cgroup 2>/dev/null; then
  export POSH_CONTAINER_KIND=docker
  export POSH_CONTAINER_KIND_SYMBOL=d
else
  export POSH_CONTAINER_KIND_SYMBOL=.
fi

eval "$(oh-my-posh init zsh --config ~/.poshthemes/my_theme.omp.json)"

# --- Options ---
setopt IGNOREEOF
setopt no_flow_control
setopt share_history
setopt hist_ignore_dups
setopt hist_ignore_all_dups
setopt auto_cd

if [[ -n "${WSL_DISTRO_NAME:-}" && "$PWD" == /mnt/* ]]; then
  cd "$HOME"
fi
