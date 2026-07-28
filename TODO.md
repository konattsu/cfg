# TODO

- Make the Neovim binary install choose the correct release archive for non-x86_64 Arch systems.
- Revisit Neovim clipboard behavior on native Linux; OSC52 may not be ideal when wl-clipboard/xclip are installed.
- Check first-run Neovim plugin installs from non-interactive or GUI-launched shells where nvm-provided npm may not be on PATH.
- git commit keyのssh鍵作成時のコメントか何かに`<user>@<machine>`と指定したつもりがmachineを固定文字列として解釈されてる
- 新しめのkeychain毎回`press enter to initialize key`みたいな警告出てありえん使いにくいので要検討. 3.0.xのやつっぽい. pacman経由だとこれ
