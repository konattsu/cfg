# cfg module 仕様

## 1. 目的

`konattsu/cfg` は、Linux 開発環境を再現するための設定リポジトリとする。

このリポジトリでは dotfiles、開発ツール、補助コマンドの導入手順を module として宣言する。module は「何を入れるか」「どこへ配置するか」「適用後に何を手動で行うか」を表す。実際の plan / apply は `scripts/cfg.py` が担う。

初回導入用の公開入口は project root の `install.sh` とする。`scripts/` は clone 済み repo 内で使う実行部を置く場所とし、`curl ... | bash` で直接呼ばれる入口は置かない。bootstrap は `git` と `python3` を前提とし、不足している場合は自動導入せず error で終了する。

初期段階では Ubuntu / Debian 系の Linux を主対象にする。macOS、Windows、GUI アプリ全般、組み込み向け環境、複雑な構成管理は対象外とする。

---

## 2. 現在の構成

```text
cfg/
  install.sh
  SPECIFICATION.md
  scripts/
    cfg.py
    plan.sh
    apply.sh
  modules/
    cargo/
      module.toml
      files/cargo.sh
    codex/
      module.toml
    core/
      module.toml
    devcontainer/
      module.toml
      files/exec_devcontainer.sh
    docker/
      module.toml
    git/
      module.toml
      files/.gitconfig
    github-cli/
      module.toml
    keychain/
      module.toml
      files/keychain.sh
    node/
      module.toml
      files/nvm.bash.sh
      files/nvm.zsh.sh
    zsh/
      module.toml
      files/zshrc.sh
      files/my_theme.omp.json
```

既存の `ai/`, `git/`, `wsl/`, `zsh/` 配下にあったスクリプトや設定は、段階的に `modules/` へ移行する。移行前のファイルは `stale/` に退避する。

AutoHotkey は Windows 用なので、この Linux 前提の module 仕様には含めない。

---

## 3. 設計方針

1. module はサービス単位で分割する。
   例: `git`, `zsh`, `node`, `codex`, `docker`

2. module は宣言だけを持つ。
   apt の一括実行、依存順の解決、PATH の反映、バックアップ、実行可否判定は executor の責務にする。

3. 初期の宣言対象は以下に限定する。
   - apt package
   - directory 作成
   - file 配置
   - artifact 取得・配置
   - command 実行
   - module 間依存
   - 実行時 PATH 追加
   - 適用後 notes

4. バージョン固定は初期段階では必須にしない。
   apt / npm / artifact は、その時点で通常取得できるものを使う。固定が必要になった時点で module ごとに検討する。

5. artifact のハッシュ値検証は初期段階では必須にしない。
   検証や pinning は後から追加できる拡張点として扱う。

6. 秘密情報とマシン固有値は repo 管理外にする。
   token、秘密鍵、署名鍵の実体、環境固有パス、認証済み状態はコミットしない。

---

## 4. module.toml

各 module は `modules/<name>/module.toml` を持つ。

```toml
name = "example"
depends_on = ["core"]
notes = ["tool の認証は初回起動後に手動で行う。"]

[packages]
apt = ["curl"]

[[dirs]]
path = "~/.ssh"
mode = "700"

[[files]]
src = "files/script.sh"
dst = "~/.local/bin/script"
mode = "755"

[[blocks]]
src = "files/zshrc.sh"
dst = "~/.zshrc"
marker = "cfg:zsh"

[[artifacts]]
name = "tool"
url = "https://example.com/tool-linux-x86_64.tar.gz"
extract = true
bin = "tool"
dst = "~/.local/bin/tool"

[[commands]]
run = "tool setup"
unless = "command -v tool"
requires = ["tool"]

[env]
path_prepend = ["~/.local/bin"]
```

### 4.1 `name`

module 名を表す。原則として `modules/<name>/` の directory 名と一致させる。

### 4.2 `packages.apt`

apt で導入する package 名の一覧。

executor は全 module の `packages.apt` を集約し、重複排除して一括 install する。module ごとに `apt install` を実行しない。

### 4.3 `dirs`

作成する directory の一覧。

```toml
[[dirs]]
path = "~/.ssh"
mode = "700"
```

- `path`: 作成先 path
- `mode`: 任意。3 桁または 4 桁の octal 文字列

`mode` は必ず `"700"` のような文字列で書く。`700` や `0755` のような数値は使わない。

owner / group / symbolic mode は初期段階では扱わない。

### 4.4 `files`

repo 内の file を配置する一覧。

```toml
[[files]]
src = "files/.gitconfig"
dst = "~/.gitconfig"
mode = "644"
```

- `src`: module directory からの相対 path
- `dst`: 配置先 path
- `mode`: 任意。3 桁または 4 桁の octal 文字列

executor は `dst` の親 directory を作成してから file を配置する。既存 file は backup なしで上書きする。`mode` が指定されている場合は配置後に chmod する。

### 4.5 `blocks`

既存 file の一部に repo 管理 block を挿入・更新する一覧。

```toml
[[blocks]]
src = "files/zshrc.sh"
dst = "~/.zshrc"
marker = "cfg:zsh"
```

- `src`: module directory からの相対 path
- `dst`: block を挿入する対象 file
- `marker`: 必須。managed block を識別する文字列

executor は `src` の内容を以下の marker で囲んで `dst` に反映する。

```sh
# >>> cfg:zsh >>>
...
# <<< cfg:zsh <<<
```

既に同じ marker block が存在する場合は、その block の中身だけを置換する。存在しない場合は file 末尾へ追加する。`dst` が存在しない場合は新規作成する。

単純な append は行わない。再実行で重複しやすく、削除や更新も難しくなるため。

MVP では marker 行の comment prefix は `#` 固定とし、shell config や ssh config など `#` comment が使える text file を対象にする。`marker` には任意の文字列を書けるが、初期実装では `>>>` や改行を含む値は想定しない。

executor は backup なしで対象 file を更新する。managed block 外の内容は変更しない。

### 4.6 `artifacts`

URL から取得する binary / archive の定義。

```toml
[[artifacts]]
name = "tool"
url = "https://example.com/tool-linux-x86_64.tar.gz"
extract = true
bin = "tool"
dst = "~/.local/bin/tool"
```

初期段階では `sha256` や version は必須にしない。必要になった場合に `sha256`, `version`, `strip_components` などを追加する。

### 4.7 `commands`

module 固有の補助 command。

```toml
[[commands]]
run = "npm install -g @openai/codex"
unless = "command -v codex"
requires = ["npm"]
```

- `run`: 実行する shell command
- `unless`: 任意。成功した場合は `run` を skip する条件 command
- `requires`: 任意。`run` 前に存在確認する command 名の一覧

`requires` は契約プログラミングの precondition に近い。依存 package の install は行わず、実行直前に command が現在の executor process から見えることを検証するための項目とする。

`requires` の値は module 名ではなく executable name とする。executor は `requires` から module 適用順を推測しない。適用順は `depends_on` だけで決める。

`run` と `unless` は複数行 command を許可する。pipe や quote を含む command は TOML の multi-line basic string を使う。

```toml
[[commands]]
run = """
curl -fsSL https://example.com/install.sh | bash
"""
unless = """
test -s "$HOME/.example/installed" &&
command -v example
"""
requires = ["curl", "bash"]
```

`unless` は既存 script の `if ! command -v ...` を module に落とすための仕組みとする。

`depends_on`、`requires`、`unless` の役割は分ける。

- `depends_on`: module 適用順を決める
- `requires`: command 実行前の precondition を検証する
- `unless`: command を skip してよいか判定する

例:

```toml
name = "codex"
depends_on = ["node"]

[[commands]]
run = "npm install -g @openai/codex"
requires = ["npm"]
```

この例では `depends_on: node` が nvm / Node.js / npm の導入順を保証し、`requires: npm` が `npm install` 実行直前の PATH 解決と存在確認を担う。

読み替えると、`requires: npm` は「この command を実行する前に、現在の executor process から `npm` が実行可能でなければならない」という契約である。

### 4.8 `env`

executor 自身の実行環境へ反映する値。

```toml
[env]
path_prepend = ["~/.local/bin"]
```

`env.path_prepend` は、後続 module の `commands` や `requires` 判定で必要な PATH を追加するために使う。

dotfile を配置して `.bashrc` や `.zshrc` を再読み込みする方式には頼らない。非対話 shell では期待通りに読み込まれないことがあり、親 shell にも反映されないため。

### 4.9 `depends_on`

先に適用する module 名の一覧。

```toml
depends_on = ["core", "node"]
```

executor は `depends_on` を使って適用順を決定する。循環依存は error とする。

基本 module の適用順は `core` を最初、`zsh` をその次にする。その他の通常 module は、明確に不要な場合を除いて `zsh` に依存させる。これにより shell 本体と `.zshrc` の基本 block を先に配置してから、NVM、Cargo、keychain などの追加 shell block を適用する。

### 4.10 `notes`

apply の最後に表示する手動作業。

```toml
notes = [
  "Git commit signing の `user.signingkey` はローカルの公開鍵に合わせて手動設定する。",
]
```

git signing key、秘密鍵、GitHub 認証、Docker group 反映のための再ログインなど、安全に自動化しづらい作業は `notes` に書く。

任意文字列を apply の引数で渡す仕組みは作らない。必要な注意事項は module 定義に固定する。

---

## 5. executor の責務

executor は以下を担う。

1. 対象 module を決定する
2. `depends_on` から適用順を解決する
3. `packages.apt` を集約し、重複排除する
4. 必要に応じて `apt update` を実行する
5. apt package を一括 install する
6. `env.path_prepend` を executor の現在プロセスへ反映する
7. `dirs` を作成し、指定された `mode` を設定する
8. `artifacts` を取得・配置する
9. `files` を配置し、指定された `mode` を設定する
10. `blocks` を挿入・更新する
11. `commands[].requires` を確認する。`npm`, `node`, `npx` は必要に応じて nvm を読み込んで再確認する
12. `commands[].unless` が成功する場合は該当 command を skip する
13. `commands[].run` を実行する
14. `notes` を module ごとに集約し、最後に表示する

root 権限操作は原則 apt と、公式 installer が必要とする範囲に限定する。

---

## 6. Node.js / npm / nvm

Node.js の version 管理は repo の責務にしない。現在は `node` module が nvm を導入し、nvm 経由で stable Node.js と npm を入れる。

`depends_on: node` は、その module の前に `node` module を適用するという意味を持つ。`node` module は以下を行う。

1. nvm install script を実行する
2. `~/.nvm/nvm.sh` を source する
3. `nvm install stable --latest-npm` を実行する
4. `nvm alias default stable` を設定する

ただし、`depends_on: node` は後続 command から `npm` が PATH 上に見えることまでは保証しない。`node` module の command 内で `~/.nvm/nvm.sh` を source しても、その PATH 変更は command の実行 shell 内だけで終わる可能性があるため。

そのため、`npm` を使う module は `commands[].requires` に `npm` を書く。

```toml
depends_on = ["node"]

[[commands]]
run = "npm install -g @devcontainers/cli"
requires = ["npm"]
```

executor は `requires: npm` を解決するとき、以下の順序で確認する。

1. 通常の `PATH` で `npm` を探す
2. 見つからず `~/.nvm/nvm.sh` が存在する場合、現在の apply process で source する
3. もう一度 `npm` を探す
4. それでも見つからなければ error にする

この resolver は nvm を install しない。`~/.nvm/nvm.sh` が存在しない場合は、`node` module が未適用または失敗した signal として扱う。

初回 `apply.sh` では次の流れを想定する。

```text
node module
  nvm を install
  nvm 経由で Node.js / npm を install

codex / devcontainer など npm 依存 module
  requires: npm
  PATH に npm がなければ ~/.nvm/nvm.sh を source
  npm が見えたら npm install -g ... を実行
```

固定 path を `env.path_prepend` に書く方式は採用しない。`~/.nvm/versions/node/<version>/bin` は導入された Node.js version に依存するため。

---

## 7. MVP executor 実装方針

executor は Python で実装する。`module.toml` は `tomllib` で読み込み、schema validation は厳しめに行う。

Python 3.11+ では `tomllib` は標準ライブラリとして使える。Python 3.10 以前で実行する場合は `tomli` package が必要になる。

`plan` と `apply` を含める。backup は作らないため、`apply` 前に `plan` で file 上書きや block 更新の対象を確認できることを安全性の前提にする。

```sh
scripts/plan.sh [module ...]
scripts/apply.sh [module ...]
```

module を指定しない場合は全 module を対象にする。module を指定した場合は、その module と `depends_on` の依存先を対象にする。

clone から apply までを一度に行う場合は root の `install.sh` を使う。

```sh
curl -fsSL https://raw.githubusercontent.com/konattsu/cfg/main/install.sh | bash
```

module を指定する場合は `bash -s --` 以降に渡す。

```sh
curl -fsSL https://raw.githubusercontent.com/konattsu/cfg/main/install.sh | bash -s -- zsh node
```

既定では `~/.local/share/cfg` に shallow clone / update して `scripts/apply.sh` を実行する。`CFG_COMMAND=plan` を指定すると `scripts/plan.sh` を実行する。

clone 先は XDG Base Directory の user data 配下として `~/.local/share/cfg` を使う。project root を永続的に残すことで再実行、plan 確認、差分確認、更新ができるようにする。ホーム直下への一時 clone と実行後の自己削除は、削除対象の誤りや再実行性の低下を避けるため既定動作にしない。

`install.sh` は `git` と `python3` の存在だけを確認する。bootstrap 内では apt などによる fallback install は行わない。

### 7.1 path 展開

- `src` は module directory からの相対 path とする
- `dst`, `dirs.path`, `env.path_prepend` は `~` のみ展開する
- `$HOME` などの shell 変数展開は parser 側では行わない
- `files.dst` と `blocks.dst` の親 directory は executor が作成する

### 7.2 mode validation

`mode` は文字列だけを許可する。`"755"` または `"0755"` のような 3 桁・4 桁の octal 文字列のみ有効とする。数値 `755` は error とする。

### 7.3 command 実行

`commands[].run` と `commands[].unless` は `bash -c` で実行する。

- `commands[].unless` は exit code 0 の場合に `run` を skip する
- `commands[].unless` が非 0 の場合は `run` を実行する
- `commands[].run` の working directory は module directory とする

### 7.4 requires validation

`commands[].requires` は executable name のみ許可する。`/`、空白、shell metacharacter を含む値は error とする。

executor は `requires` から module 依存を推測しない。install 順序は `depends_on` のみで決める。

### 7.5 blocks

`blocks` は module 適用順で処理する。複数 block が同じ file に入る場合、末尾追加の順序も module 適用順に従う。

同じ marker block が 0 個なら末尾に追加する。1 個なら置換する。2 個以上見つかった場合は、どれを置換すべきか曖昧なので error とする。

### 7.6 backup

MVP では backup を作らない。

`files` は既存 file を上書きする。`blocks` は対象 file を直接更新する。破壊的変更を避けたい場合は、事前に `plan` で変更内容を確認する前提にする。

---

## 8. 安全性ルール

- backup は作らない
- 既存 file の上書きや managed block 更新は `plan` で確認してから実行する
- `mode` は octal 文字列で書く
- secret、token、秘密鍵、署名鍵の実体は repo に置かない
- install 先は原則 `$HOME` 配下に寄せる
- dotfile の再読み込みを install 手順の前提にしない
- 自動化できない作業は `notes` に書く
- module は冪等性を意識し、必要に応じて `unless` を持つ
- `commands[].requires` は install をしない。見えるはずの command を検証し、nvm のような shell integration が必要な場合だけ executor が読み込む

---

## 9. 現在の module

### `core`

基本的な apt package を導入する。

### `git`

`git` package、`~/.gitconfig`、`~/.ssh` directory を管理する。

`user.signingkey`、SSH 秘密鍵、GitHub 側 signing key 登録は手動作業として `notes` に残す。

### `github-cli`

GitHub CLI の apt repository を追加し、`gh` を導入する。

これは通常の `packages.apt` だけでは表せない。公式手順では keyring 配置、apt source 追加、`apt update`、`apt install gh` が必要になる。

MVP では `apt_repositories` のような専用 schema は作らず、この一連の処理を `commands` に書く。将来、同種の apt repository 追加が増えた時点で専用 schema を検討する。

### `keychain`

`keychain` package と shell 初期化 block を管理する。

`keychain` は zsh 固有ではないため、`~/.zshrc` と `~/.bashrc` の両方へ managed block を追加する。

### `cargo`

rustup installer で Rust / Cargo を導入する。

executor 実行中は `env.path_prepend` で `~/.cargo/bin` を PATH に追加する。対話 shell 用には `~/.zshrc` と `~/.bashrc` の両方へ Cargo PATH managed block を追加する。

### `zsh`

zsh、Oh My Zsh、plugin、oh-my-posh、theme、`.zshrc` 内の zsh 専用 managed block を管理する。

NVM や keychain のように bash でも必要になる shell 共通設定は `zsh` module には置かず、それぞれ `node` module / `keychain` module で管理する。

login shell の変更は手動作業として `notes` に残す。

### `node`

nvm を導入し、stable Node.js と npm を導入する。

`~/.zshrc` と `~/.bashrc` の両方へ nvm 初期化 managed block を追加する。

### `codex`

`bubblewrap` と `@openai/codex` を導入する。npm が必要。

### `docker`

Docker installer を実行する。docker group 追加と再ログインは手動作業として `notes` に残す。

### `devcontainer`

`@devcontainers/cli` と `exec_devcontainer` 補助 command を導入する。`exec_devcontainer` は `mode: "755"` で配置する。

---

## 10. 今後の拡張候補

- apply 前 confirmation
- artifact の `sha256` 検証
- artifact / package の version 固定
- apt repository を表す専用 schema
- `pipx`, `cargo install`, `npm` package を表す専用 schema
- verify command
- minimal / full などの profile
