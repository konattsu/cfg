# Module System

この文書は `scripts/moi.py` の現在の挙動を書く。願望や将来案は書かない。

全てを詳細にドキュメント化する必要はない。
重要な設計や、なぜそうしたかの理由などを書く。
それっぽいドキュメントなどは意味がないだけではなく、認知負荷を増大させる負の資産であり、絶対に書かないこと。

## Process Exit

`scripts/moi.py` は以下の exit code を返す。

- `0`: `plan` または `apply` が最後まで到達した
- `1`: module 定義の検証で `ConfigError` が投げられた
- command の exit code: `commands[].run`、`commands[].unless` 以外の実行 command、または package manager command が `subprocess.CalledProcessError` を返した

`ConfigError` の場合、stderr に以下の形式で出力する。

```text
error: <message>
```

command 実行が exit code `N` で失敗した場合、stderr に以下を出力し、process も `N` を返す。

```text
error: command failed with exit code N
```

この文書で「停止する」と書く場合、以降の module 処理を実行せず、上記の exit code で process を終了することを指す。

## Entry Points

clone 済み repo で使う command:

```sh
./scripts/plan.sh [--platform auto|debian|arch] [module ...]
./scripts/apply.sh [--platform auto|debian|arch] [module ...]
```

`scripts/plan.sh` は `python3 scripts/moi.py plan "$@"` を実行する。

`scripts/apply.sh` は `python3 scripts/moi.py apply "$@"` を実行する。

`install.sh` は以下を行う。

1. `MOI_SELF_URL` から `moi.sh` を download する
2. `MOI_SELF_PATH` に executable file として配置する
3. `"$MOI_SELF_PATH" "$@"` を実行する

default:

```sh
MOI_SELF_URL=https://raw.githubusercontent.com/konattsu/moi/main/moi.sh
MOI_SELF_PATH=~/.local/bin/moi
```

`moi` は以下を行う。

1. `MOI_NO_SELF_UPDATE=1` でなければ `MOI_SELF_URL` から自分自身を download する
2. `MOI_SELF_PATH` と download 結果が違う場合、`MOI_SELF_PATH` を置き換えて `exec "$MOI_SELF_PATH" "$@"` で再実行する
3. `mktemp -d` で一時 directory を作る
4. EXIT trap で一時 directory を削除する
5. `git clone --depth 1 --branch "$MOI_BRANCH" "$MOI_REPO_URL" "<tmpdir>"` を実行する
6. `"<tmpdir>/scripts/<command>.sh" "$@"` を実行する

`moi` default:

```sh
MOI_REPO_URL=https://github.com/konattsu/moi.git
MOI_BRANCH=main
MOI_SELF_URL=https://raw.githubusercontent.com/konattsu/moi/main/moi.sh
MOI_SELF_PATH=~/.local/bin/moi
```

`moi` は第一引数が `plan` / `apply` の場合、その command を実行する。第一引数がない場合、または第一引数が `plan` / `apply` 以外の場合は `apply` を実行する。

## Module Selection

module は `modules/<name>/module.toml` で定義する。

`name` は `<name>` と一致しなければならない。一致しない場合は `ConfigError` で停止する。

`plan` / `apply` に module 名を渡さない場合、`modules/*/module.toml` を持つ全 directory を読む。

`plan git keychain` のように module 名を渡した場合、渡した module と、その `depends_on` を再帰的に読む。

存在しない module 名を渡した場合は `ConfigError` で停止する。

`depends_on` に存在しない module 名を書いた場合は `ConfigError` で停止する。

dependency cycle がある場合は `ConfigError` で停止する。

処理順:

- 依存先を先に処理する
- 同じ階層の module は module 名の辞書順で処理する

## module.toml Keys

top-level で読める key:

- `name`
- `depends_on`
- `followups`
- `packages`
- `dirs`
- `files`
- `blocks`
- `commands`
- `artifacts`
- `env`

上記以外の key がある場合は `ConfigError` で停止する。

## platform

`dirs` / `files` / `blocks` / `artifacts` / `commands` は `platform` を持てる。

```toml
[[commands]]
platform = "arch"
run = "..."
```

schema:

- `platform`: 省略可。`common` / `debian` / `arch` のいずれか。省略時は `common`

`common` は全 platform で適用する。

`debian` / `arch` は対象 platform と一致する場合だけ適用する。

同じ `dst` や marker への複数定義は検出しない。module 定義側で避ける。

対象 platform は既定で `/etc/os-release` の `ID` / `ID_LIKE` から自動判定する。
`--platform debian` / `--platform arch` を指定した場合はその値を使う。

## packages

```toml
[packages]
apt = ["git", "curl"]
pacman = ["git", "curl"]
```

schema:

- `apt`: 省略可。Debian platform で使う package 名の string list
- `pacman`: 省略可。Arch platform で使う package 名の string list

`apply` は選択 module から対象 platform の package list を集める。重複する package 名は 1 回にまとめる。

package が 1 個以上ある場合、module 個別処理の前に以下を実行する。

Debian:

```sh
sudo apt update
sudo apt upgrade -y
sudo apt install -y <packages...>
```

Arch:

```sh
sudo pacman -Syu --needed <packages...>
```

`plan` は package 名を表示するだけで、package manager command を実行しない。

## dirs

```toml
[[dirs]]
path = "~/.ssh"
mode = "700"
```

schema:

- `path`: 必須 string
- `mode`: 省略可。書く場合は string。`^[0-7]{3,4}$` に一致しなければ `ConfigError` で停止する
- `platform`: 省略可。`platform` と同じ規則

path expansion:

- `~` は `Path.home()` に変換する
- `~/x` は `Path.home() / "x"` に変換する
- `$HOME`、`${HOME}`、その他 `$` を含む path は `ConfigError` で停止する

`apply` の処理:

1. `path.mkdir(parents=True, exist_ok=True)` を実行する
2. `mode` があれば `path.chmod(int(mode, 8))` を実行する

結果:

- directory が存在しない場合は作成する
- directory が存在する場合も停止しない
- `mode` があれば既存 directory の mode も変更する
- directory 内の file / directory は作成・上書き・削除しない
- owner / group は変更しない

`plan` は `dir <path> mode=<mode>` を表示するだけで filesystem を変更しない。

## files

```toml
[[files]]
src = "files/config"
dst = "~/.config/moi/git/config"
mode = "644"
```

schema:

- `src`: 必須 string。absolute path は `ConfigError` で停止する
- `dst`: 必須 string
- `mode`: 省略可。書く場合は string。`^[0-7]{3,4}$` に一致しなければ `ConfigError` で停止する
- `platform`: 省略可。`platform` と同じ規則

path expansion:

- `dst` の `~` / `~/...` は `dirs.path` と同じ規則で展開する
- `dst` に `$` が含まれる場合は `ConfigError` で停止する

`apply` の処理:

1. `module.path / src` が通常 file でなければ `ConfigError` で停止する
2. `dst.parent.mkdir(parents=True, exist_ok=True)` を実行する
3. `shutil.copyfile(src, dst)` を実行する
4. `mode` があれば `dst.chmod(int(mode, 8))` を実行する

結果:

- `dst` が存在しない場合は作成する
- `dst` が存在する場合は backup なしで内容を置き換える
- `dst` が symlink の場合、Python `shutil.copyfile` の挙動に従う。独自の symlink 判定はしない

local 値を書き込む file を `[[files]]` に入れると、次回 `apply` で local 値は消える。

## blocks

```toml
[[blocks]]
src = "files/keychain.sh"
dst = "~/.zshrc"
marker = "moi:keychain"
```

schema:

- `src`: 必須 string。absolute path は `ConfigError` で停止する
- `dst`: 必須 string
- `marker`: 必須 string。`>>>` または改行を含む場合は `ConfigError` で停止する
- `platform`: 省略可。`platform` と同じ規則

path expansion:

- `dst` の `~` / `~/...` は `dirs.path` と同じ規則で展開する
- `dst` に `$` が含まれる場合は `ConfigError` で停止する

marker line:

```sh
# >>> moi:keychain >>>
# <<< moi:keychain <<<
```

`#` は固定。module 定義では変更できない。

`apply` の処理:

1. `module.path / src` が通常 file でなければ `ConfigError` で停止する
2. `dst.parent.mkdir(parents=True, exist_ok=True)` を実行する
3. `dst` があれば UTF-8 text として読む。なければ既存 content を空文字列にする
4. start line と end line を探す
5. start/end の数が違えば `ConfigError` で停止する
6. start が 2 個以上あれば `ConfigError` で停止する
7. start が end より後にあれば `ConfigError` で停止する
8. block がなければ file 末尾へ追加する
9. block が 1 個あれば start line から end line までを置き換える
10. `dst.write_text(updated, encoding="utf-8")` を実行する

追加時の空行:

- 既存 content が newline で終わらなければ newline を 1 個足す
- block 追加前に、既存 content の末尾が newline 3 個になるまで newline を足す

結果:

- marker block 外の text はそのまま残る
- marker block 内の手編集は次回 `apply` で `src` の内容に戻る
- local 値は marker block 内に書かない。marker block から別 file を `source` する

## commands

```toml
[[commands]]
run = "npm install -g @openai/codex"
unless = "command -v codex"
requires = ["npm"]
```

schema:

- `run`: 必須 string
- `platform`: 省略可。`platform` と同じ規則
- `unless`: 省略可。書く場合は string
- `requires`: 省略可。書く場合は string list

`requires`:

- 値は executable name のみ
- `^[A-Za-z0-9._+-]+$` に一致しなければ `ConfigError` で停止する
- `/`、空白、shell metacharacter は書けない

`apply` の処理:

1. `requires` の各 command を `shutil.which(command, PATH)` で確認する
2. command が `node` / `npm` / `npx` の場合、見つからなければ `~/.nvm/nvm.sh` を読み込んでから再確認する
3. 見つからない `requires` があれば `ConfigError` で停止する
4. `unless` があれば `bash -c <unless>` を module directory で実行する
5. `unless` の exit code が 0 なら `run` を実行しない
6. `unless` の exit code が 0 以外なら `bash -c <run>` を module directory で実行する
7. `run` が exit code 0 以外を返した場合、`scripts/moi.py` は同じ exit code で停止する

`apply --ignore-unless` の場合、上記 4 と 5 を行わず、`commands[].run` を実行する。

`requires` は module の順序を変更しない。順序は `depends_on` だけで決まる。

`unless = "command -v tool"` は、`tool` が PATH にあれば `run` しないという意味になる。既存 tool の version は確認しない。

## env.path_prepend

```toml
[env]
path_prepend = ["~/.local/bin"]
```

schema:

- `path_prepend`: 省略可。書く場合は string list
- item に `$` が含まれる場合は `ConfigError` で停止する

`apply` / `plan` の処理:

1. module 処理の先頭で展開する
2. 各 path の `~` / `~/...` を `dirs.path` と同じ規則で展開する
3. executor process の `PATH` 先頭に追加する

この変更は現在の `scripts/moi.py` process と、その子 process にだけ効く。ユーザーの親 shell の `PATH` は変更しない。

## followups

```toml
followups = ["Run `gh auth login` to authenticate with GitHub."]
```

`followups` は手動の後続作業として表示する文字列。実行しない。

表示条件:

- `install.sh` 経由の初回導入では表示する
- `--show-followups` を指定した場合は表示する
- `--no-followups` を指定した場合は表示しない
- 通常の `plan` / `apply` では表示しない

`scripts/moi.py` は `scripts/followup-wsl.sh` の存在を参照しない。

## State Boundaries

この repo では `apply` が以下を変更する。

- `[[dirs]]` の directory と mode
- `[[files]]` の destination file 全体
- `[[blocks]]` の marker block 内
- `[[commands]]` が実行する command の結果

`apply` は以下を変更しない。

- SSH 秘密鍵
- `~/.ssh/allowed_signers`
- GitHub login
- default shell
- docker group membership
- keychain に渡す個別 key

上の一覧にある file を `[[files]]` に入れると、`apply` が file 全体を上書きする。この repo では入れない。

## Current Module Decisions

### Module Dependencies

`depends_on` は module の成果物に必要な前提だけを書く。

- `~/.zshrc` に block を入れる module は `zsh` に依存する
- `~/.bashrc` に block を入れる module は `bash` に依存する
- shell completion など shell 別の file を配置・生成する module は該当 shell module に依存する
- command 実行時だけ必要な executable は `depends_on` ではなく `requires` に書く

### Shell Editors

`modules/zsh` は `~/.zshrc` に editor 用 marker block を入れる。

`modules/bash` は `~/.bashrc` に editor 用 marker block を入れる。

block の実行内容:

```sh
export EDITOR=vim
export VISUAL=vim
export GIT_EDITOR=vim
```

### Git

`modules/git` は `~/.gitconfig` を `[[files]]` で配置しない。

`modules/git` は以下を配置する。

```text
~/.config/moi/git/config
```

この include 先で `core.editor = vim` を設定する。

`modules/git` は以下を 1 回だけ追加する。既に同じ include path がある場合は追加しない。

```sh
git config --global --add include.path "$HOME/.config/moi/git/config"
```

Git user, email, signing key, `allowed_signers` は `modules/git` では設定しない。

### Keychain

`modules/keychain` は `~/.zshrc` と `~/.bashrc` に marker block を入れる。

block の実行内容:

1. `~/.config/moi/keychain.local.sh` が readable なら `source` する
2. readable でなければ `eval "$(keychain --eval)"` を実行する

個別 key を読み込ませる場合は `~/.config/moi/keychain.local.sh` に書く。

```sh
eval "$(keychain --eval ~/.ssh/git_commit)"
```

### Follow-up

`scripts/followup-wsl.sh` は `install.sh` と `scripts/moi.py` から呼ばれない。

この script が触るもの:

- `chsh -s /bin/zsh`
- `~/.ssh/git_commit`
- `~/.ssh/git_commit.pub`
- `~/.ssh/allowed_signers`
- `git config --global user.name`
- `git config --global user.email`
- `git config --global user.signingkey`
- `git config --global gpg.format`
- `git config --global gpg.ssh.allowedSignersFile`
- `git config --global commit.gpgsign`
- `sudo usermod -aG docker`
- `gh auth login`

## Version Selection

一部 module は install 時に latest release を取得する。

該当例:

- `modules/lazygit`
- `modules/yazi`
- `modules/nvim`

`unless` の exit code が 0 の場合は再取得しない。つまり、初回実行時点の latest が残る。

## Validation Commands

module 読み込みと plan 表示:

```sh
python3 scripts/moi.py plan [module ...]
```

shell syntax:

```sh
bash -n install.sh moi.sh scripts/apply.sh scripts/plan.sh scripts/followup-wsl.sh
```
