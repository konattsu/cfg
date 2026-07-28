# moi

Linux(Debian/Arch) 用の環境をセットアップする repo

## 仕組み

実行は次の3段階に分かれている。

1. `install.sh` がlauncherの `moi.sh` をダウンロードし、`~/.local/bin/moi` に配置する
2. `moi` がこのリポジトリの最新 `main` を一時ディレクトリへcloneする
3. clone内の `scripts/moi.py` が `modules/*/module.toml` を読み、planまたはapplyを実行する

`install.sh` は初回導入用であり, 環境設定そのものは行わない.
launcherを配置したあと, 渡された引数でそのまま `moi` を起動する.
以降は `moi` を直接使えばよい。

`moi` は通常、実行時にlauncher自身を更新し, 最新のリポジトリを一時cloneする.
そのためローカルにcloneを維持する必要はなく, 一時cloneは実行後に削除される.

## Install

`install.sh` には `curl`, その後の `moi` 実行には `git` と `python3` が必要.

```sh
curl -fsSL https://raw.githubusercontent.com/konattsu/moi/main/install.sh | bash
```

これは `moi` をインストールして, そのまま全モジュールをapplyする.
変更内容だけ確認する場合:

```sh
curl -fsSL https://raw.githubusercontent.com/konattsu/moi/main/install.sh | bash -s -- plan
```

## Usage

```sh
moi plan [--platform auto|debian|arch] [--show-followups|--no-followups] [module ...]
moi apply [--platform auto|debian|arch] [--show-followups|--no-followups] [module ...]
```

`plan` は予定されるモジュール, パッケージ, ファイル, コマンドを表示するだけで変更しない.
`apply` はそれらを実際に適用する. サブコマンドを省略した場合は `apply` になる.

モジュールを省略するとすべてを対象にする.
指定した場合は、そのモジュールと `depends_on` の依存先を対象にする.

対象 platform は `/etc/os-release` から自動判定する.
確認時は明示指定できる.

```sh
moi plan --platform arch
moi plan --platform debian
```

手動の後続作業は `install.sh` 経由の初回導入では自動表示される.
通常の `moi plan` / `moi apply` では表示しない.
必要な場合は明示指定する.

```sh
moi plan --show-followups
moi apply --show-followups
```

編集中のローカルcheckoutをそのまま実行する場合はlauncherを経由しない.

```sh
./scripts/plan.sh [module ...]
./scripts/apply.sh [module ...]
```

## applyの範囲

`apply` は `module.toml` に定義されたディレクトリ, ファイル, marker block, パッケージ, バイナリ, セットアップコマンドを適用する.

SSH秘密鍵, `~/.ssh/allowed_signers`, GitHub login, default shell, docker group membership, keychainに読み込ませる個別の鍵は上書きしない.

## その他

- 初回セットアップ後の対話的な作業には以下が便利
  - debian: `curl -fsSL https://raw.githubusercontent.com/konattsu/moi/main/scripts/followup-debian.sh | bash -s -- --yes`
  - arch: `curl -fsSL https://raw.githubusercontent.com/konattsu/moi/main/scripts/followup-arch.sh | bash -s -- --yes`
- Neovim本体, AstroNvim, プラグインの更新方法は [docs/nvim.md](docs/nvim.md) を参照
- モジュール定義の仕様は [SPECIFICATION.md](SPECIFICATION.md) を参照
