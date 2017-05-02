+++
date = "2017-05-03T00:30:00Z"
tags = ["fzf","zsh","開発環境"]
title = "pecoからfzfに移行した"

+++

今までずっと [peco](https://github.com/peco/peco) を使ってきたが、そろそろ別のツールに変えてみるか...と思い立ったので [fzf](https://github.com/junegunn/fzf) に移行した。

[junegunn/fzf: A command-line fuzzy finder written in Go](https://github.com/junegunn/fzf)

自分は基本的に飽き性なので、定期的に環境を変えたくなる時期が来るのだが fzf が思ってたより良かったので紹介したい。

<!--more-->

## fzfとは

こちらの記事が参考になる。

[おい、peco もいいけど fzf 使えよ - Qiita](http://qiita.com/b4b4r07/items/9e1bbffb1be70b6ce033)

peco と同じく golang 製の command line fuzzy finder である。

インストールは brew で一発でできる。

```
$ brew install fzf
```

本当は zplug を使ってインストールしたかったのだが fzf にバンドルされている fzf-tmux が使えなさそうだったので brew で入れた。

ただ fzf-tmux よりも通常の fzf の方が好きなので結果的には zplug でインストールしても良かったかもしれない。

zplug の場合はこのように書く。

```zsh
zplug "junegunn/fzf-bin", \
    from:gh-r, \
    as:command, \
    rename-to:fzf, \
    use:"*darwin*amd64*"
```

何気に `from:gh-r` でコマンドをインストールするのは初めてだった。

これを使わないと zplug を使うメリットが全くないと思うので自然に使っていきたい。

## どこが良かったか

主にかっこよさ、見た目の部分。

かっこいいとテンションが上がってコードを書くモチベーションが上がるので非常に大事なこと。

なぜか peco よりも使っていて気持ち良かった。まだ使い始めて1日も経ってないけど。

[![https://gyazo.com/379d26198bb54dae277122effca4cbab](https://i.gyazo.com/379d26198bb54dae277122effca4cbab.gif)](https://gyazo.com/379d26198bb54dae277122effca4cbab)

あと peco は画面を全て占領するのだが fzf は画面下部にそのまま出てくれる。これがすこぶる良い。

視線の移動が少ないため、負荷が少ない。

[![https://gyazo.com/f975b8292153cbbac0d0dbe02853d982](https://i.gyazo.com/f975b8292153cbbac0d0dbe02853d982.gif)](https://gyazo.com/f975b8292153cbbac0d0dbe02853d982)

## 既存の peco 関連のスクリプトを fzf 用に書き換えた

多分 `$FILTER` とか環境変数に入れて置けばいちいち書き換える必要もないんだろうけど、どうせしばらく fzf 使うだろうしそのまま書き換えてしまった。

<script src="https://gist.github.com/tsub/29bebc4e1e82ad76504b1287b4afba7c.js"></script>

<script src="https://gist.github.com/tsub/90e63082aa227d3bd7eb4b535ade82a0.js"></script>

<script src="https://gist.github.com/tsub/81ac9b881cf2475977c9cb619021ef3c.js"></script>

<script src="https://gist.github.com/tsub/f4036e067a59b242a161fc3c8a5f01dd.js"></script>

<script src="https://gist.github.com/tsub/4448666a276b088bce3f19005f512c15.js"></script>

## zplug + b4b4r07/gist が良かった

今回 zsh の function を gist に置いて [zplug](https://github.com/zplug/zplug) で管理する、ということをやってみた。

```zsh
zplug "tsub/4448666a276b088bce3f19005f512c15", from:gist # ghq-fzf.zsh
zplug "tsub/f4036e067a59b242a161fc3c8a5f01dd", from:gist # history-fzf.zsh
zplug "tsub/81ac9b881cf2475977c9cb619021ef3c", from:gist # ssh-fzf.zsh
zplug "tsub/90e63082aa227d3bd7eb4b535ade82a0", from:gist # git-branch-fzf.zsh
zplug "tsub/29bebc4e1e82ad76504b1287b4afba7c", from:gist # tree-fzf.zsh
```

こうすると zplug が gist からファイルを読み込んでくれて非常に便利だった。

また、 gist の管理は [b4b4r07/gist](https://github.com/b4b4r07/gist) を使った。

b4b4r07/gist は zplug でインストールした。こちらは brew で配布されていなかった。

```zsh
zplug "b4b4r07/gist", from:gh-r, as:command, use:"*darwin*amd64*"
```

新規 gist の作成と、 その後の zsh function の編集などが非常に楽だった。

`$ gist edit` で gist 一覧が表示され、その中からファイルを選択するとエディターが立ち上がる。保存して終了すればすぐさまアップロードされる。

[![https://gyazo.com/dd4eaf166313a242872de95a86a2a5cd](https://i.gyazo.com/dd4eaf166313a242872de95a86a2a5cd.gif)](https://gyazo.com/dd4eaf166313a242872de95a86a2a5cd)

そして `$ zplug update` を実行すればローカルに clone してきた gist が更新される。

## まとめ

ということで fzf + zplug + b4b4r07/gist が非常に素晴らしかったので使っていく。

また飽きたら他のツールを巡ろうと思う。
