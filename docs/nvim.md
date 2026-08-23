# Neovim

## 構成

このリポジトリではNeovim関連を3層に分けて管理する。

- **Neovim**: エディタ本体。moduleで指定した固定versionの公式tarballを展開して
  `~/.local/share/nvim-linux-x86_64` に配置する。
- **AstroNvimとプラグイン**: Neovim上で動くLuaプラグイン群。`lazy.nvim` と
  `lazy-lock.json` が管理する。
- **設定**: `environments/host/modules/nvim/files` に置き、`moi apply nvim` で
  `~/.config/nvim` へコピーする。

Neovim本体とプラグインは同じ世代で固定する。現在は Neovim `0.12.4` と
repository管理の `lazy-lock.json` を使う。Neovim `0.13` 系へ移るときは、
Neovim本体のversionとlockfileを同じ更新作業で変更する。

## Neovim本体の更新

`moi apply nvim` は指定versionのNeovimが既にあればインストールを省略する。
既存環境のNeovimだけを更新する場合は、module内の `NVIM_VERSION` と `unless`
のversion判定を変更してから `moi apply nvim` を実行する。

```sh
moi apply nvim
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
いくつか開いて確認する。問題がなければ生成された `~/.config/nvim/lazy-lock.json`
を module配下のlockfileへ反映する。

## lockfile

lazy.nvimは `~/.config/nvim/lazy-lock.json` を使ってプラグインのcommitを固定する。
このリポジトリでは host と devcontainer の module配下に同じ内容のlockfileを置き、
`moi apply nvim` で `~/.config/nvim/lazy-lock.json` へ配置する。

`pin_plugins` は `nil` のままにし、プラグイン固定はlockfileへ集約する。
host と devcontainer のlockfileは同じ内容に保つ。現在は devcontainer 側にだけ
`conform.nvim` のspecがあるため、lockfile更新はplugin specのsupersetである
devcontainer 側で行う。host 側で生成したlockfileをそのまま反映すると、
devcontainer 専用pluginのentryが落ちる可能性がある。

## 通常の更新順序

1. Neovim本体を更新する場合は、host/devcontainer両方の `NVIM_VERSION` と `unless` を変更する。
2. `moi apply nvim` で指定versionのNeovimと既存lockfileを配置する。
3. `:Lazy update` でAstroNvimとプラグインを更新する。
4. Neovimを再起動し、必要ならもう一度 `:Lazy update` を実行する。
5. `:checkhealth` と普段使うfiletypeで確認する。
6. 問題がなければ `~/.config/nvim/lazy-lock.json` を host/devcontainer両方の
   `files/lazy-lock.json` へ反映する。
