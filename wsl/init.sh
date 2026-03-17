#!/usr/bin/env bash


set -euo pipefail

info() { echo -e "\033[1;34m[INFO]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $*"; }

if [[ $EUID -ne 0 ]]; then
  error "Please run this script as root"
  exit 1
fi

cd ~

info "Updating package list..."
apt-get update -y

info "Installing core development tools"
apt-get install -y --no-install-recommends \
  build-essential \
  ca-certificates \
  curl \
  ffmpeg \
  git \
  gnupg \
  keychain \
  libssl-dev \
  lsb-release \
  net-tools \
  pkg-config \
  unzip \
  wget

info "Installing GitHub CLI (gh)..."
if ! command -v gh >/dev/null 2>&1; then
# ref: https://github.com/cli/cli/blob/trunk/docs/install_linux.md#debian
  (type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
    && sudo mkdir -p -m 755 /etc/apt/keyrings \
    && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && sudo mkdir -p -m 755 /etc/apt/sources.list.d \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && sudo apt update \
    && sudo apt install gh -y
else
  info "gh is already installed: $(command -v gh)"
fi

info "Installing Rust + Cargo..."
if ! command -v cargo >/dev/null 2>&1; then
  # ref: https://rust-lang.org/tools/install
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
else
  info "cargo is already installed: $(command -v cargo)"
fi

info "Installing script in order to install Docker"
info "Please execute the following command to install Docker: 'sudo sh ./get-docker.sh && usermod -aG docker $USER'"
# ref: https://qiita.com/ain1084/items/6cb6d82852c91416ec0e
curl -fsSL https://get.docker.com -o get-docker.sh

info "Done."
