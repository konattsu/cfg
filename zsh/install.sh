#!/usr/bin/env bash

set -euo pipefail

# 1. apt 更新
sudo apt-get update
sudo apt-get upgrade -y

# 2. 必要ツール
sudo apt-get install -y zsh git curl unzip fontconfig

# 3. zsh をデフォルトシェルにする
chsh -s "$(which zsh)"

# 4. Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

zsh

# 5. zsh plugins
git clone https://github.com/zsh-users/zsh-autosuggestions \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# 6. Oh My Posh
curl -s https://ohmyposh.dev/install.sh | bash -s

# PATH 反映
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
export PATH="$HOME/.local/bin:$PATH"

# 7. themes
mkdir -p ~/.poshthemes
curl -fsSL https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip -o /tmp/themes.zip
unzip -o /tmp/themes.zip -d ~/.poshthemes
chmod u+rw ~/.poshthemes/*.omp.json
