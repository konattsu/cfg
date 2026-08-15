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
eval "$(oh-my-posh init zsh --config ~/.poshthemes/my_theme.omp.json)"

# --- Options ---
setopt IGNOREEOF
setopt no_flow_control
setopt share_history
setopt hist_ignore_dups
setopt hist_ignore_all_dups
setopt auto_cd

cd
