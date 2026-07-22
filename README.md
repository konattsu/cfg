# cfg

Linux 開発環境を再現するための設定リポジトリ

`apt install`, `npm install`, `dotfilesの配置/更新` などを自動で適用するためのスクリプトを提供

## Usage

```sh
curl -fsSL https://raw.githubusercontent.com/konattsu/cfg/main/install.sh | bash
```

```sh
# plan only (i.e. dry-run)
curl -fsSL https://raw.githubusercontent.com/konattsu/cfg/main/install.sh | CFG_COMMAND=plan bash
```

- 以下のコマンドが必須:
  - `git`
  - `python3`

### Manual follow-up

WSL で disposable な環境を作る場合は、apply 後の manual follow-up を補助するスクリプトを実行すると便利

`followup-wsl` は `modules/*/module.toml` の `notes` にある manual follow-up を元に、`chsh`, Git commit signing 用 SSH key, `allowed_signers`, docker group, `gh auth login` を補助する。

`apply` は disposable WSL 環境の初期状態を作るためのものとして扱う。`followup-wsl` 実行後に再度 `apply` すると、`allowed_signers` などの local state は初期状態で上書きされうる。

```sh
curl -fsSL https://raw.githubusercontent.com/konattsu/cfg/main/scripts/followup-wsl.sh | bash
```

全 follow-up section を選択する場合:

```sh
curl -fsSL https://raw.githubusercontent.com/konattsu/cfg/main/scripts/followup-wsl.sh | bash -s -- --yes
```

- `--yes` は各 section の選択確認を省略するだけで、`ssh-keygen`, `chsh`, `gh auth login` などのコマンド自体の対話は残る

## Structure

- `modules/`: 自動適用の対象
- `extras/`: 自動適用とは別に単にgithubに保存しときたい設定
