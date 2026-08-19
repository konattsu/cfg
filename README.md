# moi

Linux(Debian/Arch) 用の環境をセットアップする repo

## Install

`install.sh` には `curl` が必要.
source が `https://` の場合は `moi` 実行時に `git` も必要.

```sh
curl -fsSL https://raw.githubusercontent.com/konattsu/moi/main/install.sh \
  | MOI_ENVIRONMENT=host bash -s -- apply
```

これは GitHub Releases の latest から環境に合う `moi` binary を `~/.local/bin/moi` に配置し、`~/.config/moi/config.toml` を作成して、全モジュールを apply する。
変更内容だけ確認する場合は `plan` を使う。

## Usage

```sh
moi [--environment ENV] [--folder-name NAME] [--source SOURCE] [--quiet|-v...] plan [--platform auto|debian|arch] [--show-followups|--no-followups] [module ...]
moi [--environment ENV] [--folder-name NAME] [--source SOURCE] [--quiet|-v...] apply [--platform auto|debian|arch] [--show-followups|--no-followups] [--ignore-unless] [module ...]
```

`plan` は予定されるモジュール, パッケージ, ファイル, コマンドを表示するだけで変更しない.
`apply` はそれらを実際に適用する.

モジュールを省略するとすべてを対象にする。指定した場合は、そのモジュールと `depends_on` の依存先を対象にする.

対象 platform は `/etc/os-release` から自動判定する。確認時は明示指定できる.

```sh
moi plan --platform arch
moi plan --platform debian
```

`--environment`, `--folder-name`, `--source`, `--quiet`, `-v` / `--verbose` は command の前後どちらにも置ける。
`--quiet` は通常出力を抑制する。`-v` / `--verbose` は診断出力を増やす。
`apply --ignore-unless` は `commands.unless` を評価せず `commands.run` を実行する。

編集中のローカル checkout をそのまま実行する場合:

```sh
MOI_ENVIRONMENT=host MOI_SOURCE=file:///$PWD ./scripts/plan.sh [module ...]
MOI_ENVIRONMENT=host MOI_SOURCE=file:///$PWD ./scripts/apply.sh [module ...]
```

`scripts/plan.sh` / `scripts/apply.sh` は `MOI_SOURCE` が未指定なら現在の checkout を使う。

## 設定

設定ファイルは `~/.config/moi/config.toml` に置く。

```toml
default_environment = "host"
default_folder_name = "environments"
default_source = "https://github.com/konattsu/moi.git"
```

設定値は command line argument, environment variable, 設定ファイルの順で決まる。
`default_folder_name` と `default_source` は設定がなければ上記の既定値を使う。
`environment` と操作 `plan` / `apply` は必須。

| value | command line | environment |
| --- | --- | --- |
| environment | `--environment` | `MOI_ENVIRONMENT` |
| folder name | `--folder-name` | `MOI_FOLDER_NAME` |
| source | `--source` | `MOI_SOURCE` |

## 仕組み

実行は次の流れ。

1. `install.sh` が GitHub Releases の latest から `moi` binary をダウンロードし、`~/.local/bin/moi` に配置する
2. `moi` が設定から source, folder, environment を決める
3. source が `https://` の場合は一時ディレクトリへ clone し、`file:///` の場合はその checkout を使う
4. `moi` が `<folder>/<environment>/modules/*/module.toml` を読み、plan または apply を実行する

source が `https://` の場合、一時 clone は実行後に削除する。

## applyの範囲

`apply` は `module.toml` に定義されたディレクトリ, ファイル, marker block, パッケージ, バイナリ, セットアップコマンドを適用する.

SSH秘密鍵, `~/.ssh/allowed_signers`, GitHub login, default shell, docker group membership, keychainに読み込ませる個別の鍵は上書きしない.

## その他

- 初回セットアップ後の対話的な作業には以下が便利
  - debian: `curl -fsSL https://raw.githubusercontent.com/konattsu/moi/main/scripts/followup-debian.sh | bash -s -- --yes`
  - arch: `curl -fsSL https://raw.githubusercontent.com/konattsu/moi/main/scripts/followup-arch.sh | bash -s -- --yes`
- Neovim本体, AstroNvim, プラグインの更新方法は [docs/nvim.md](docs/nvim.md) を参照
- モジュール定義の仕様は [SPECIFICATION.md](SPECIFICATION.md) を参照
