# Module System

この文書は Rust 実装の現在の挙動を書く。願望や将来案は書かない。

## Process Exit

`moi` は以下の exit code を返す。

- `0`: `plan` または `apply` が最後まで到達した
- `1`: module 定義、設定、I/O、download などのエラー
- command の exit code: `commands[].run`、package manager、`git clone` が失敗した場合

stderr の形式:

```text
error: <message>
```

command 実行が exit code `N` で失敗した場合:

```text
error: command failed with exit code N
```

## Entry Points

install:

```sh
curl -fsSL https://raw.githubusercontent.com/konattsu/moi/main/install.sh \
  | MOI_ENVIRONMENT=host bash -s -- apply
```

`install.sh` は GitHub Releases の latest から実行中 OS/architecture に合う asset を download し、`MOI_SELF_PATH` に executable file として配置してから実行する。

default:

```sh
MOI_GITHUB_REPOSITORY=konattsu/moi
MOI_SELF_PATH=~/.local/bin/moi
MOI_RELEASE_BASE=https://github.com/konattsu/moi/releases/latest/download
MOI_RELEASE_ASSET=moi-<target-triple>
```

対応 target:

- `x86_64-unknown-linux-gnu`
- `aarch64-unknown-linux-gnu`

clone 済み repo で使う local wrapper:

```sh
./scripts/plan.sh [--quiet|-v...] [--platform auto|debian|arch] [--show-followups|--no-followups] [module ...]
./scripts/apply.sh [--quiet|-v...] [--platform auto|debian|arch] [--show-followups|--no-followups] [--ignore-unless] [--upgrade-packages] [module ...]
```

local wrapper は `MOI_SOURCE` が未指定なら現在の checkout を `file://` source として使う。`target/debug/moi` があればそれを実行し、なければ `cargo run` を実行する。

直接実行:

```sh
moi [--environment ENV] [--folder-name NAME] [--source SOURCE] [--quiet|-v...] plan [options] [module ...]
moi [--environment ENV] [--folder-name NAME] [--source SOURCE] [--quiet|-v...] apply [options] [module ...]
```

`moi` は `plan` / `apply` のどちらかの操作を必須とする。
`--environment`, `--folder-name`, `--source`, `--quiet`, `-v` / `--verbose` は command の前後どちらにも置ける。
`--quiet` は通常出力を抑制する。`-v` / `--verbose` は診断出力を増やし、複数回指定できる。

## Settings

設定ファイル:

```sh
~/.config/moi/config.toml
```

schema:

```toml
default_environment = "host"
default_folder_name = "environments"
default_source = "https://github.com/konattsu/moi.git"
```

設定値は command line argument, environment variable, 設定ファイルの順に解決する。

| value | command line | environment | config |
| --- | --- | --- | --- |
| environment | `--environment` | `MOI_ENVIRONMENT` | `default_environment` |
| folder_name | `--folder-name` | `MOI_FOLDER_NAME` | `default_folder_name` |
| source | `--source` | `MOI_SOURCE` | `default_source` |

`environment` が解決できない場合は停止する。
`folder_name` が解決できない場合は `environments` を使う。
`source` が解決できない場合は `https://github.com/konattsu/moi.git` を使う。

`source` は `https://` または `file:///` で始まらなければ停止する。
`folder_name` は repository-relative path で、absolute path または `..` を含む場合は停止する。

設定ファイルが存在しない場合、`moi` は解決後の値を `~/.config/moi/config.toml` に書く。

## Repository Source

`source` が `https://` で始まる場合、`moi` は一時 directory を作り、以下を実行する。

```sh
git clone --depth 1 --branch "$MOI_BRANCH" "$source" "<tmpdir>"
```

`MOI_BRANCH` の default は `main`。

`source` が `file:///` で始まる場合、その path を repository root として使う。

設定 repository は release binary に含めない。`moi` は実行ごとに `source` から module 定義と配置 file を読む。

## Module Selection

module は `<folder_name>/<environment>/modules/<name>/module.toml` で定義する。

`name` は directory 名と一致しなければならない。

module 名を渡さない場合、`module.toml` を持つ全 module を読む。
module 名を渡した場合、渡した module と、その `depends_on` を再帰的に読む。

停止条件:

- 存在しない module 名を指定した
- `depends_on` に存在しない module 名を書いた
- dependency cycle がある
- `module.toml` に未知の key がある

処理順:

- 依存先を先に処理する
- 同じ階層の module は module 名の辞書順で処理する

top-level key:

- `name`
- `depends_on`
- `followups`
- `packages`
- `dirs`
- `files`
- `blocks`
- `commands`
- `env`

## Platform

`dirs` / `files` / `blocks` / `commands` は `platform` を持てる。

```toml
[[commands]]
platform = "arch"
run = "..."
```

`platform` は `common` / `debian` / `arch` のいずれか。省略時は `common`。

`common` は全 platform で適用する。
`debian` / `arch` は対象 platform と一致する場合だけ適用する。

対象 platform は既定で `/etc/os-release` の `ID` / `ID_LIKE` から自動判定する。
`--platform debian` / `--platform arch` を指定した場合はその値を使う。

## Packages

```toml
[packages]
apt = ["git", "curl"]
pacman = ["git", "curl"]
```

`apply` は選択 module から対象 platform の package list を集める。重複する package 名は 1 回にまとめる。

Debian:

```sh
sudo apt update
sudo apt install -y <packages...>
```

Arch:

```sh
sudo pacman -S --needed --noconfirm <packages...>
```

`apply --upgrade-packages` を指定した場合、Debian では `sudo apt upgrade -y` を実行してから install する。Arch では `pacman -S` の代わりに `pacman -Syu` を使う。

`plan` は package 名を表示するだけで package manager command を実行しない。

## Paths

`dirs.path`, `files.dst`, `blocks.dst`, `env.path_prepend` の path expansion:

- `~` は `$HOME` に変換する
- `~/x` は `$HOME/x` に変換する
- `$` を含む path は停止する

`files.src` と `blocks.src` は module-relative path。absolute path または `..` を含む場合は停止する。

`dirs.mode` と `files.mode` は 3-4 桁の 8 進数 string。表示時は 4 桁の 8 進数に正規化する。

## Dirs

```toml
[[dirs]]
path = "~/.ssh"
mode = "700"
```

`apply`:

1. directory を `parents=true, exist_ok=true` で作成する
2. `mode` があれば existing directory も含めて mode を変更する

owner / group は変更しない。

## Files

```toml
[[files]]
src = "files/config"
dst = "~/.config/moi/git/config"
mode = "644"
```

`apply`:

1. `module.path / src` が通常 file でなければ停止する
2. `dst.parent` を作成する
3. `src` を `dst` へ copy する
4. `mode` があれば `dst` の mode を変更する

`dst` が存在する場合は backup なしで内容を置き換える。

## Blocks

```toml
[[blocks]]
src = "files/keychain.sh"
dst = "~/.zshrc"
marker = "moi:keychain"
```

marker line:

```sh
# >>> moi:keychain >>>
# <<< moi:keychain <<<
```

`marker` は空文字、`>>>`、改行を含めない。

`apply`:

1. `module.path / src` が通常 file でなければ停止する
2. `dst.parent` を作成する
3. `dst` があれば UTF-8 text として読む。なければ空文字列にする
4. marker block がなければ file 末尾へ追加する
5. marker block が 1 個あれば start line から end line までを置き換える
6. start/end の数が違う、複数ある、順序が逆の場合は停止する

追加時は、既存 content が空でない場合だけ block 前に空行を入れ、末尾が newline 3 個になるまで newline を足す。

## Commands

```toml
[[commands]]
run = "npm install -g @openai/codex"
unless = "command -v codex"
requires = ["npm"]
```

`requires` は executable name のみ。ASCII 英数字、`.`、`_`、`+`、`-` 以外を含む場合は停止する。

`apply`:

1. `requires` の各 command を `PATH` から探す
2. command が `node` / `npm` / `npx` の場合、見つからなければ `~/.nvm/nvm.sh` を読み込んだ PATH で再確認する
3. 見つからない `requires` があれば停止する
4. `unless` があれば `bash -c <unless>` を module directory で実行する
5. `unless` の exit code が 0 なら `run` を実行しない
6. `unless` の exit code が 0 以外なら `bash -c <run>` を module directory で実行する

`apply --ignore-unless` は `unless` を評価せず `run` を実行する。

`plan` は `unless` / `run` を実行しない。

## env.path_prepend

```toml
[env]
path_prepend = ["~/.local/bin"]
```

module 処理の先頭で展開し、executor process の `PATH` 先頭に追加する。
この変更は `moi` process と、その子 process にだけ効く。

## Follow-ups

```toml
followups = ["Run `gh auth login` to authenticate with GitHub."]
```

`followups` は手動の後続作業として表示する文字列。実行しない。

表示条件:

- `install.sh` 経由の初回導入では表示する
- `--show-followups` を指定した場合は表示する
- `--no-followups` を指定した場合は表示しない
- 通常の `plan` / `apply` では表示しない

## State Boundaries

`apply` が変更するもの:

- `[[dirs]]` の directory と mode
- `[[files]]` の destination file 全体
- `[[blocks]]` の marker block 内
- `[[commands]]` が実行する command の結果

`apply` がこの repo で直接管理しないもの:

- SSH 秘密鍵
- `~/.ssh/allowed_signers`
- GitHub login
- default shell
- docker group membership
- keychain に渡す個別 key

これらは `followups` または `scripts/followup-*.sh` の範囲に置く。
