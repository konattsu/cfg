#!/usr/bin/env bash

set -euo pipefail

sudo apt-get update
sudo apt-get install -y bubblewrap
npm install -g @openai/codex
