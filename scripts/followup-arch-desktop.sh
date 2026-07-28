#!/usr/bin/env bash
set -euo pipefail

# Reserved for Arch desktop follow-ups such as Hyprland, portals, fonts,
# input methods, audio, graphics drivers, and other GUI-session concerns.
# The desktop environment is not defined yet, so this file is intentionally
# not executable as a follow-up entry point.

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "error: followup-arch-desktop.sh is a placeholder; run followup-arch.sh for now." >&2
  exit 1
fi
