+++
date = "2016-06-30T23:56:16+09:00"
tags = ["elixir", "イベントレポート"]
title = "tokyo.ex #3 参加してきた"

+++

tokyo.ex #3 に参加してきました。

[tokyo.ex #3](http://beam-lang.connpass.com/event/32704/)

前々からtokyo.ex #1, #2と気にはなっていたんですが、気づいた時には定員が埋まってまして今回やっと参加できました。

と思ってたらわりと席空いてたりキャンセル多かったり、定員超えてるからといって諦めなくても良かったみたいですね

参加してみての全体的な感想ですが、正直最近elixirを触ってなかったのでいい刺激になりました。

話の内容は非常にレベルが高く、大半は理解できませんでしたが、その分elixirの勢いとコミュニティの熱さは十分伝わってきました。

<!--more-->

さて、簡単に各LTのまとめとか書いていきます。

## モニタリングの話 @junsumidaさん
<script async class="speakerdeck-embed" data-id="9612ccd4961a413085ae4e9c6b868060" data-ratio="1.33333333333333" src="//speakerdeck.com/assets/embed.js"></script>

elixirで書いたアプリケーションのメトリックとかどうやって出してるかの話

Elixirのメトリックを取得できるライブラリは有名ドコロで下記の3つらしい

- [pinterest/elixometer](https://github.com/pinterest/elixometer)
- [hahuang65/beaker](https://github.com/hahuang65/beaker)
- [rwdaigle/metrix](https://github.com/rwdaigle/metrix)

今回はelixometerに加えて、erlangのメトリックライブラリのexometerを使った

アプリケーションの情報をelixometerを使って取得し、erlang vmの情報はexometerを使って取得した

モニタリングにはsensuを使ってる

また、それとは別に今後はfluentdでログをとってelasticsearchに送ってkibanaで見れるようにする予定らしい

elixometerとexometerを使うにあたって一番苦労したポイントはloggerとlaggerの競合

exometerがlagger(erlangのlogger)に送り、elixometerがlogger(elixirのlogger)に送っているため、同時に使うと競合してしまう。

そのため、laggerとloggerの間にlagger_loggerというものを作って受け渡ししている

## メタプログラミングの話 @tuvistavieさん
[Metprogramming in Elixir](http://tuvistavie.com/slides/metaprogramming/)

予想以上に日本語ペラペラだった！

今回の話でいうメタプログラミングは「自分自身を変えられる」という定義で話す

elixirでメタプロするにはASTというものを利用する

AST(Abstract Syntax Tree)はプログラムの構文木

macroを駆使してelixirでDSLを作ることができる

danielさんが作ったDSLでコマンド定義できるライブラリ

[https://github.com/tuvistavie/ex_cli:embed:cite]

## phoenix channelの話 @hdtkkjさん
<script async class="speakerdeck-embed" data-id="52520f55289f4c0f96388346d7db3c13" data-ratio="1.33333333333333" src="//speakerdeck.com/assets/embed.js"></script>

phoenixのchannelの使い方と、パフォーマンスを計測した話

channelは、transport, pubsub, channelの3つの層に分かれてる

pubsubはredisとかpg2とかrabbit mqとか差し替え可能

elixirはプロセスをたくさん生み出して処理するのに強いこともあり、100000プロセスとか立てても普通に動く

## elixirでhoundを使ってみて @hayabusa333さん
[HashNuke/hound](https://github.com/HashNuke/hound)

EtoEテストを書くためのライブラリ

他の言語とそれほど変わらない形で書ける

elixirにImageMagickのwrapperはあるが、画像比較する実装はまだないのでページスクリーンショットの比較とかはできない

## success typing @_ko1さん
プログラミングelixir 日本語訳版 8月発売予定

_関数が使えるならマクロは使ってはならない_

マクロはここぞという時の必殺技みたいなもの

使い過ぎると自分が辛くなる

dialyzer

success typing

matzさんがerlangのdialyzerがなかなか良いのでruby3.0に取り入れたいと言ってたらしい
_上司は思いつきでものを言う_ 笑ったww

success typingに関する論文がある(2006)

今更erlangで型を強制することができないので、それなりにミスをチェックできるゆるふわな型システム = success typing

確実に間違いと分かるもののみチェックしたい

プログラムの書き方によってチェックできたりできなかったりする = 意味ないんじゃない?と言われたらしい

## 最後に
前回取ったアンケートを参考に初級者向けのphoenixハンズオンをやることになったらしい

[tokyo.ex #4 phoenixハンズオン](http://beam-lang.connpass.com/event/34985/)

また、中級者向けのハンズオンも別途検討中らしい

あと、ElixirConf.japan検討中らしい
