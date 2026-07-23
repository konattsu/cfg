# --- keychain ---
cfg_keychain_local="$HOME/.config/cfg/keychain.local.sh"
if [[ -r "$cfg_keychain_local" ]]; then
  source "$cfg_keychain_local"
else
  eval "$(keychain --eval)"
fi
unset cfg_keychain_local
