+++
date = "2016-07-02T22:08:23+09:00"
tags = ["vim"]
title = "neovimのterminal emulatorが便利すぎた"

+++

少し前にvimからneovimに移行したのですが、vimよりさくさくな気がする、程度でneovimの機能を特に活用していませんでした。

実はneovimにはterminal emulatorという機能があり、vimの中でshellを起動することができます。

例えばコードを書きつつ、rspecを実行したりpryやtigを使ったりなど、非常に便利です。

[![](https://gyazo.com/ca4b9ef1599801f1948721befe274654.png)](https://gyazo.com/ca4b9ef1599801f1948721befe274654.png)

<!--more-->

## 簡単な使い方の紹介
terminal emulatorを起動するには`:terminal`を実行します。

起動すると最初はキーバインドがterminal modeになっています。

そのままlsなどを実行すれば実行できると思います。

`<C-\><C-n>`でcommand modeにすることができます。

command modeから再びterminal modeにするには、insert modeに入るときのように`i`や`a`などでできます。

terminal emulatorを終了したいときはterminal mode中にexitなどで普通にshellを終了させるか、command modeで`:q`などを使えばvimごと終了できます。

## 自分がやった設定
デフォルトのままでは使いづらいため、いくつか自分が設定した項目を紹介します。

### デフォルトで起動するshellを変える
terminal emulatorはデフォルトでshを起動しますので、普段使っているshell環境でなかったり、パスが通ってなかったりで使いづらいです。

デフォルトで起動するshellは以下のように書くことで変えることができます。

```vim
" ~/.config/nvim/init.vim

set sh=zsh
```

### ESCでcommand modeにする
terminal mode中は、insert modeなどと違い、command modeに戻るためのデフォルトのキーバインドが`<C-\><C-n>`となっています。

このままでは使いづらいので、ESCでcommand modeに戻れるように設定します。

terminal mode内でkey mapを設定したい場合は`tnoremap`で設定できます。

[Vim documentation: nvim_terminal_emulator](https://neovim.io/doc/user/nvim_terminal_emulator.html)

```vim
" ~/.config/nvim/init.vim

tnoremap <silent> <ESC> <C-\><C-n>
```

最初は`jj`でも戻れるように設定していたのですが、terminal mode内でtigなど、vimライクなキーバインドのツールを使うときに困ったため、ESCのみ設定しています。

もしinsert modeと同じように`jj`でcommand modeにしたい場合は以下のように書けば良いと思います。

```vim
" ~/.config/nvim/init.vim

tnoremap <silent> jj <C-\><C-n>
```

### neotermを使う

[kassio/neoterm](https://github.com/kassio/neoterm)

上述したように特にvim pluginを入れずともneovimは`:terminal`でterminal emulatorを使うことができます。

ただ、neotermを入れることで`:T tig`のように任意のコマンドを実行し、かつsplitウィンドウでterminalを起動することができるようになります。

また私は使っていませんが、neoterm側でテストコマンドやREPLをサポートしており、いちいち`:T bundle exec rspec`や`:T bundle exec pry`のようにせずとも一発で立ち上げることもできます。

## おまけ
vimの中でemacsを起動する、という芸当もできます

[![](https://gyazo.com/b97d25325e66dc121da6edb933354b2d.png)](https://gyazo.com/b97d25325e66dc121da6edb933354b2d.png)
