# --- keychain ---
moi_keychain_local="$HOME/.config/moi/keychain.local.sh"
if [[ -r "$moi_keychain_local" ]]; then
  source "$moi_keychain_local"
else
  eval "$(keychain --eval)"
fi
unset moi_keychain_local
