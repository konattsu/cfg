# --- interactive only ---
[[ -o interactive ]] || return

# --- Oh My Zsh ---
export ZSH="$HOME/.oh-my-zsh"

plugins=(
  git
  zsh-syntax-highlighting
  zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

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
