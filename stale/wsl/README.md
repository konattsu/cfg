# 色々

## execution

一部非対話。`sudo`を内部で使っていて、このパスワード入力のみ必要

```bash
curl -fsSL -o ~/wsl_init.sh https://raw.githubusercontent.com/konattsu/cfg/main/wsl/init.sh
chmod +x ~/wsl_init.sh
~/wsl_init.sh
```

## default shell

上のシェルではデフォルトシェル変更できないので、手動で変更する

```bash
chsh -s /bin/zsh
```

## keychain

- win側にあるものを`cp`してwsl側に移動した際には, ファイルモードの変更が必須
  - 秘密鍵: 600
  - 公開鍵: 644

```bash
mkdir ~/.ssh
chmod 700 ~/.ssh
```

`.bashrc`, `.zshrc`
```bash
eval "$(keychain --eval <秘密鍵へのパス. 複数可>)"
```
