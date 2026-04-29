#!/usr/bin/env bash


set -euo pipefail

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y zsh git curl unzip fontconfig

# install Oh My Posh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# plugins
mkdir -p "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions \
    "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
fi
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
fi

# Oh My Posh
curl -fsSL https://ohmyposh.dev/install.sh | bash -s

export PATH="$HOME/.local/bin:$PATH"

mkdir -p ~/.poshthemes
curl -fsSL https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip -o /tmp/themes.zip
unzip -o /tmp/themes.zip -d ~/.poshthemes
find ~/.poshthemes -name '*.omp.json' -exec chmod u+rw {} +
