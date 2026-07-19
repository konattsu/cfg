# Neovim 設定の整理メモ

このメモは、`modules/nvim` に置いた AstroNvim ベースの設定を cfg として使える状態にするための作業リスト。
Neovim 自体に詳しくなくても、まずは下の順番で見ればよい。

## 現状の結論

この設定は AstroNvim テンプレートとしての形はあるが、まだ「どの環境でも `cfg apply nvim` 後にそのまま動く」とは言い切れない。

特に危ない点は次の 3 つ。

1. ローカル plugin `~/dev/github/nvim-office` を起動時に読む `office.lua` は削除済み。
2. `modules/nvim/module.toml` は apt の `neovim` ではなく、公式 AppImage を `~/.local/bin/nvim` に入れる方針にした。
3. Mason 系を無効化しているため、LSP / formatter / linter は全部 PATH に別途入っている前提になっている。

## まずやること

### 1. Neovim 本体の入れ方 - Done

Ubuntu Noble の apt 候補は古い。

```text
neovim/noble 0.9.5-6ubuntu2 amd64
```

一方で設定は AstroNvim v6 系のテンプレートで、`lazy_setup.lua` には AstroNvim snapshot が指定されている。

```lua
version = "2026.05.05-84a231c"
```

`rust.lua` でも `nvim-0.11` を見て plugin version を切り替えている。

```lua
version = vim.fn.has "nvim-0.11" == 1 and "^6" or "^5"
```

つまり、apt の `neovim 0.9.5` 前提はかなり怪しい。
そのため `modules/nvim/module.toml` では apt の `neovim` を使わず、公式 release の AppImage を `~/.local/bin/nvim` に配置する。

現在の方針:

- `https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage` を使う。
- 配置先は `~/.local/bin/nvim`。
- `~/.local/bin` は `module.toml` の `[env].path_prepend` で PATH に入れる。
- 既に `~/.local/bin/nvim` があり、`NVIM v0.11` 以上なら再 download しない。

残 TODO:

- AppImage が FUSE 不足で動かない環境に当たったら、公式手順どおり `--appimage-extract` fallback を検討する。
- ARM Linux も対象にするなら `nvim-linux-arm64.appimage` への切り替えを追加する。

### 2. `office.lua` は削除済み

個人テンプレートに含まれていた `office.lua` は削除した。
これはローカル plugin `~/dev/github/nvim-office` を起動時に読む設定だった。

```lua
dir = vim.fn.expand("~/dev/github/nvim-office"),
lazy = false,
build = "npm install --omit=dev",
```

この repo には `nvim-office` の実体がなく、cfg として再現できないため不要と判断した。

対応済み:

- `modules/nvim/files/lua/plugins/office.lua` を削除。
- `modules/nvim/module.toml` の配置エントリも削除。

### 3. Mason は LSP 用に使う

Mason は formatter / linter / debugger には広げず、LSP server の導入だけに使う。
保存時の自動整形は無効のままにする。

```lua
{ "mason-org/mason-null-ls.nvim", enabled = false },
{ "jay-babu/mason-nvim-dap.nvim", enabled = false },
```

`mason.nvim` と `mason-lspconfig.nvim` は有効化する。
`mason-null-ls.nvim` と `mason-nvim-dap.nvim` は無効のまま。

導入対象の LSP:

- Lua: `lua_ls`
- Go: `gopls`
- Rust: `rust_analyzer`
- TypeScript / JavaScript: `ts_ls`
- Python: `pyright`
- Shell: `bashls`
- TOML: `taplo`
- JSON: `jsonls`
- YAML: `yamlls`
- Markdown: `marksman`
- Dockerfile: `dockerls`
- Docker Compose: `docker_compose_language_service`
- HTML: `html`
- CSS: `cssls`

対応済み:

- formatter/linter 用の `none-ls.nvim` / `nvim-lint` 設定は削除。
- `format_on_save.enabled = false` を維持。
- OXC / ruff formatter / selene lint などは外した。

### 4. AstroCommunity の重複は削除済み

`modules/nvim/files/lua/community.lua` に同じ import が重複していた。

```lua
{ import = "astrocommunity.scrolling.nvim-scrollbar" },
{ import = "astrocommunity.recipes.picker-nvchad-theme" },
{ import = "astrocommunity.recipes.disable-borders" },
```

対応済み:

- 重複していた `nvim-scrollbar`, `picker-nvchad-theme`, `disable-borders` の import を削除。

### 5. Clipboard 方針を確認する

`modules/nvim/files/lua/polish.lua` はこうなっている。

```lua
if vim.fn.has "wsl" == 1 then
  vim.g.clipboard = "win32yank"
else
  vim.g.clipboard = "osc52"
end

vim.opt.clipboard:append "unnamedplus"
```

WSL では `win32yank.exe` が必要。
Linux Desktop では OSC 52 を使う設定なので、`wl-clipboard` / `xclip` を apt で入れていても直接使っていない可能性がある。

TODO:

- WSL を主対象にするなら `win32yank.exe` の導入手順を notes に残す。
- Linux Desktop を主対象にするなら `wl-clipboard` / `xclip` を使う設定に寄せるか確認する。
- Ghostty など OSC 52 対応 terminal 前提なら、今のままでよい。

対応予定:

- modules/ にオプション追加しようかなと
- args取ってwslとか判定するとややこしいのでそもそもpackage名だけ取ろうかなと

### 6. Dashboard は GitHub CLI に依存する

`modules/nvim/files/lua/plugins/dashboard.lua` は dashboard から GitHub CLI を呼ぶ。

```lua
gh issue list --web
gh pr list --web
```

対応済み:

- dashboard action で `gh` を使うため、`nvim` module は `github-cli` に依存する。
- `github-cli` module 側の note に従い、初回は `gh auth login` が必要。

## ファイルの見方

Neovim は `init.lua` から始まる。
この設定では、入口はかなり薄く、ほとんどは `lua/` 以下に分割されている。

主に見る場所:

- `modules/nvim/files/init.lua`: 入口。Lazy.nvim を bootstrap して `lazy_setup` と `polish` を読む。
- `modules/nvim/files/lua/lazy_setup.lua`: AstroNvim 本体、community、plugins の読み込み設定。
- `modules/nvim/files/lua/community.lua`: AstroCommunity の追加 preset。
- `modules/nvim/files/lua/polish.lua`: 最後に当てる個人設定。clipboard など。
- `modules/nvim/files/lua/plugins/astro/core.lua`: 基本オプション、keymap、AstroCore 設定。
- `modules/nvim/files/lua/plugins/astro/lsp.lua`: LSP 全体設定。format on save、semantic token、on_attach など。
- `modules/nvim/files/lua/plugins/astro/ui.lua`: colorscheme、highlight、icons。
- `modules/nvim/files/lua/plugins/*.lua`: 個別 plugin 設定。
- `modules/nvim/files/lua/plugins/lang/init.lua`: 読み込む言語設定の一覧。
- `modules/nvim/files/lua/plugins/lang/*.lua`: 言語別の LSP / formatter / treesitter 設定。
- `modules/nvim/files/lazy-lock.json`: plugin lockfile。基本は手で触らない。
- `modules/nvim/files/dot_luarc.json`: Lua LSP 用の設定。配置時は `~/.config/nvim/.luarc.json` になる。

57 個くらいファイルがあるのは、巨大な `init.lua` に全部書かず、plugin / 言語 / UI / LSP で分けているから。
普段触るのはだいたい次だけ。

- `lua/plugins/astro/core.lua`
- `lua/plugins/astro/lsp.lua`
- `lua/plugins/astro/ui.lua`
- `lua/plugins/lang/*.lua`
- `lua/community.lua`
- `lua/polish.lua`

## 動作確認の順番

まずは「起動するか」だけを見る。LSP は後回し。

1. `cfg apply nvim` 相当で `~/.config/nvim` に配置されることを確認する。
2. `nvim --version` で Neovim の version を確認する。
3. `nvim --headless '+Lazy! sync' +qa` で plugin install が通るか確認する。
4. `nvim --headless '+checkhealth' +qa` で大きな問題を見る。
5. 普通に `nvim` を起動して、起動時エラーが出ないか確認する。
6. Lua ファイルを開いて `lua-language-server` まわりを見る。
7. TypeScript / Rust / Go など、よく使う言語から順に LSP を確認する。

## 優先度つき TODO

### P0: 起動失敗を潰す

- AppImage 版の `~/.local/bin/nvim` で `nvim --version` が `0.11` 以上になるか確認する。
- 実際に `nvim --headless '+Lazy! sync' +qa` を流す。

### P1: 再現性を決める

- Mason で LSP server が入るか初回起動後に確認する。
- `module.toml` の apt package が本当に必要か見直す。

### P2: 設定を整理する

- 使っていない plugin ファイルを無効化または削除する。
- `jujutsu.lua.disabled` は使わないなら削除候補。

### P3: 使いながら調整する

- keymap は `astro/core.lua` に寄せる。
- 見た目は `astro/ui.lua` に寄せる。
- clipboard など個人環境差が強いものは `polish.lua` に寄せる。
- 言語ごとの不満は `plugins/lang/*.lua` に閉じ込める。

## すぐ消してよさそうなもの

まだ判断が必要だが、候補はこれ。

- `modules/nvim/files/lua/plugins/jujutsu.lua.disabled`: `.disabled` なので通常読み込まれない。

消す前に、元テンプレートからの意図が必要かだけ確認する。

## 最終的に目指す形

最初のゴールは「全部入り高機能 Neovim」ではなく、次の状態。

- `cfg apply nvim` で Neovim が入る。
- `~/.config/nvim` に設定が配置される。
- 初回 `nvim` で plugin install が通る。
- Lua / TypeScript / Rust など、よく使う 2-3 言語だけ LSP が動く。
- ローカル絶対パスや未導入コマンドが原因で起動失敗しない。
