# Neovim Mason/LSP 導入候補

目的は「VSCode を開くほどではないが、コードを読みたい」時の Neovim。
formatter / linter / debugger は最初は広げすぎない。
まずは Mason で LSP server だけ入れる方針にする。

## 基本方針

- `mason.nvim`: 使う
- `mason-lspconfig.nvim`: 使う
- `mason-tool-installer.nvim`: まず使わない
- `mason-null-ls.nvim`: まず使わない
- `mason-nvim-dap.nvim`: まず使わない
- `none-ls.nvim`: formatter/linter が欲しくなるまで後回し
- `nvim-lint`: lint が欲しくなるまで後回し
- `conform.nvim`: format が欲しくなるまで後回し
- `format_on_save`: 無効のままにする

## まず入れる LSP

| 対象 | LSP 名 | Mason package | 用途 |
| --- | --- | --- | --- |
| Lua | `lua_ls` | `lua-language-server` | Neovim 設定編集、rename、定義ジャンプ |
| Go | `gopls` | `gopls` | Go の定番 LSP |
| Rust | `rust_analyzer` | `rust-analyzer` | Rust の定番 LSP |
| TypeScript / JavaScript | `ts_ls` | `typescript-language-server` | TS/JS の標準寄り LSP |
| Python | `pyright` | `pyright` | Python の補完、型情報、rename |
| Shell | `bashls` | `bash-language-server` | `sh`, `bash`, `zsh` |
| TOML | `taplo` | `taplo` | TOML |
| JSON | `jsonls` | `json-lsp` | JSON / JSONC |
| YAML / YML | `yamlls` | `yaml-language-server` | YAML / YML |
| Markdown | `marksman` | `marksman` | Markdown の見出し、リンク、参照 |
| Dockerfile | `dockerls` | `dockerfile-language-server` | Dockerfile |
| Docker Compose | `docker_compose_language_service` | `docker-compose-language-service` | compose yaml |
| HTML | `html` | `html-lsp` | HTML |
| CSS | `cssls` | `css-lsp` | CSS / SCSS / LESS |

## Markdown について

今の設定には Markdown 表示向けに以下が入っている。

- `astrocommunity.markdown-and-latex.render-markdown-nvim`
- `astrocommunity.markdown-and-latex.markdown-preview-nvim`

`render-markdown.nvim` は Neovim 内で Markdown の見た目を整える plugin。
表、コードブロック、引用、見出しなどを見やすくする目的。

`markdown-preview.nvim` はブラウザ preview 用の plugin。

`marksman` はそれらとは別で、Markdown 用の LSP。
表示を綺麗にするものではなく、次のような編集支援を担当する。

- 見出しへの jump
- workspace 内 Markdown link の補完
- link 先の diagnostics
- document symbols
- rename / references 系の LSP 機能

結論として、`render-markdown.nvim` / `markdown-preview.nvim` と `marksman` は併用できる。
役割が違うので、Markdown 表示 plugin を流用したまま `marksman` を入れてよい。

## 最小構成のイメージ

最初はこれくらいでよい。

```lua
ensure_installed = {
  "lua_ls",
  "gopls",
  "rust_analyzer",
  "ts_ls",
  "pyright",
  "bashls",
  "taplo",
  "jsonls",
  "yamlls",
  "marksman",
  "dockerls",
  "docker_compose_language_service",
  "html",
  "cssls",
}
```

formatter / linter はここには入れない。
保存時の自動整形も無効のままにする。

## 注意点

- Mason package 名と lspconfig の server 名は同じとは限らない。
- `mason-lspconfig.nvim` を使えば、基本的には LSP server 名で `ensure_installed` できる。
- TypeScript は `ts_ls` から始めるのが無難。
- Rust はまず `rust_analyzer` だけでよい。`rustaceanvim` は後で必要になったら検討する。
- Docker Compose は YAML LSP とは別に `docker_compose_language_service` を使える。
