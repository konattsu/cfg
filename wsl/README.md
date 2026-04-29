# 色々

## execution

```bash
curl -fsSL -o ~/wsl_init.sh https://raw.githubusercontent.com/konattsu/cfg/main/wsl/init.sh
chmod +x ~/wsl_init.sh
~/wsl_init.sh
```

## keychain

`.bashrc`
```bash
eval "$(keychain --eval <秘密鍵へのパス. 複数可>)"
```

- win側にあるものを`cp`してwsl側に移動した際には, ファイルモードの変更が必須
  - chmod type path/to/file
