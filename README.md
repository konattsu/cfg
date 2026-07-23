# cfg

Linux / WSL 用の個人設定 repo。

`install.sh` はこの repo を一時 directory に clone し、`scripts/apply.sh` を実行する。

同じ環境で再実行する前提で書いている。一時 clone は実行後に削除する。`apply` は SSH 秘密鍵、`~/.ssh/allowed_signers`、GitHub login、docker group、default shell、keychain の個別 key 指定を上書きしない。

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/konattsu/cfg/main/install.sh | bash
```

実行内容の表示だけ:

```sh
curl -fsSL https://raw.githubusercontent.com/konattsu/cfg/main/install.sh | CFG_COMMAND=plan bash
```

`install.sh` 実行前に必要な command:

- `git`
- `python3`

## Local Commands

clone 済み repo では以下を使う。

```sh
./scripts/plan.sh [module ...]
./scripts/apply.sh [module ...]
```

`module ...` を省略すると全 module を読む。指定すると、その module と `depends_on` に書かれた module を読む。

## Files Changed by apply

`apply` が変更するもの:

- `[[dirs]]` に書いた directory
- `[[files]]` に書いた destination file 全体
- `[[blocks]]` に書いた marker block 内
- `[[commands]]` が実行する installer や setup command

`apply` が変更しないもの:

- SSH 秘密鍵
- `~/.ssh/allowed_signers`
- GitHub login
- default shell
- docker group membership
- keychain に読み込ませる個別 key

## Follow-up

WSL で初回セットアップ後の手作業をまとめたい場合:

```sh
curl -fsSL https://raw.githubusercontent.com/konattsu/cfg/main/scripts/followup-wsl.sh | bash
```

`--yes` なしでは prompt する。`curl ... | bash` でも `/dev/tty` から入力を読むため対話できる。

確認を省略して全 section を選ぶ場合:

```sh
curl -fsSL https://raw.githubusercontent.com/konattsu/cfg/main/scripts/followup-wsl.sh | bash -s -- --yes
```

`followup-wsl.sh` は `scripts/cfg.py` から呼ばれない。`install.sh` からも呼ばれない。

## Keychain Local File

keychain に読み込ませる鍵を指定する場合:

```sh
mkdir -p ~/.config/cfg
printf '%s\n' 'eval "$(keychain --eval ~/.ssh/git_commit)"' > ~/.config/cfg/keychain.local.sh
```

`~/.config/cfg/keychain.local.sh` は `modules/keychain` の `[[files]]` に入れていないため、`apply` はこの file を作成・上書き・削除しない。

## Module System

`modules/*/module.toml` の読み方と実行順は [SPECIFICATION.md](SPECIFICATION.md) に書く。
