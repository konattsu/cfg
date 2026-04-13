# 色々

## keychain

`.bashrc`
```bash
eval "$(keychain --eval <秘密鍵へのパス. 複数可>)"
```

- win側にあるものを`cp`してwsl側に移動した際には, ファイルモードの変更が必須
  - chmod type path/to/file
