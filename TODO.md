# TODO

- Make the Neovim binary install choose the correct release archive for non-x86_64 Arch systems.
- Revisit Neovim clipboard behavior on native Linux; OSC52 may not be ideal when wl-clipboard/xclip are installed.
- Check first-run Neovim plugin installs from non-interactive or GUI-launched shells where nvm-provided npm may not be on PATH.
- git commit keyのssh鍵作成時のコメントか何かに`<user>@<machine>`と指定したつもりがmachineを固定文字列として解釈されてる
- 新しめのkeychain毎回`press enter to initialize key`みたいな警告出てありえん使いにくいので要検討. 3.0.xのやつっぽい. pacman経由だとこれ
- 折り返しは単語の途中にならないような挙動になってるが, 使いにくいのでそこまでは伸ばしてそこで無理やり切る方針で. あと, インデントがあるとき, 折り返したやつもインデントあるのは嫌だが今の状態分からんので要確認
- `:bd`でwindowも消えるので要確認
