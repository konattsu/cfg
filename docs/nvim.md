# Neovim

## 構成

このリポジトリではNeovim関連を3層に分けて管理する。

- **Neovim**: エディタ本体。公式の最新stable tarballを展開して
  `~/.local/share/nvim-linux-x86_64` に配置する。
- **AstroNvimとプラグイン**: Neovim上で動くLuaプラグイン群。`lazy.nvim` が管理する。
- **設定**: `environments/host/modules/nvim/files` に置き、`moi apply nvim` で
  `~/.config/nvim` へコピーする。

AstroNvimは `version = "^6"` とし、6.xのstable releaseを追従する。7.xへの更新は
明示的にversion指定を変更したときだけ行われる。

## Neovim本体の更新

`moi apply nvim` はNeovim 0.11以上が既にあればインストールを省略する。既存環境の
Neovimだけを更新する場合は、次のコマンドで公式の最新stable tarballを入れ直す。

```sh
tmpdir="$(mktemp -d)"
curl -fL \
  https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz \
  -o "$tmpdir/nvim-linux-x86_64.tar.gz"

rm -rf "$HOME/.local/share/nvim-linux-x86_64"
tar -xzf "$tmpdir/nvim-linux-x86_64.tar.gz" -C "$HOME/.local/share"
ln -sfn \
  "$HOME/.local/share/nvim-linux-x86_64/bin/nvim" \
  "$HOME/.local/bin/nvim"

rm -rf "$tmpdir"
nvim --version
```

これはNeovim本体だけを更新し、設定やプラグインを変更しない。

## AstroNvimとプラグインの更新

Neovim内で次を実行する。

```vim
:Lazy update
```

AstroNvim本体の更新後に追加の更新が表示される場合は、Neovimを再起動してもう一度
`:Lazy update` を実行する。更新後は `:checkhealth` を実行し、普段使うfiletypeを
いくつか開いて確認する。

## lockfile

lazy.nvimは `~/.config/nvim/lazy-lock.json` をローカルに生成する。このリポジトリでは
lockfileを管理・配置しないため、新しい環境ではその時点の最新版がインストールされる。
既存環境のlockfileは `moi apply nvim` で上書きされず、その環境の更新状態として残る。

## 通常の更新順序

1. 必要なときだけNeovim本体を更新する。
2. `:Lazy update` でAstroNvimとプラグインを更新する。
3. Neovimを再起動し、必要ならもう一度 `:Lazy update` を実行する。
4. `:checkhealth` と普段使うfiletypeで確認する。
5. 問題がなければそのまま利用する。lockfileをリポジトリへコピーする必要はない。
