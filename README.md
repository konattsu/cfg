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

## Structure

- `modules/`: 自動適用の対象
- `extras/`: 自動適用とは別に単にgithubに保存しときたい設定

## License

Apache-2.0
