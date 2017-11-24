+++
tags = ["Go", "Datadog", "Alfred"]
date = "2017-11-26T16:00:00+09:00"
title = "Go で Datadog の Alfred Workflow を作った"
+++

最近会社の同僚が [Alfred Workflow を Go で書いたという LT を発表していて](http://developer.feedforce.jp/entry/2017/11/13/085404)面白そうだったので、自分も書いてみました。

以下のリポジトリで配布しています。

<i class="fa fa-github"></i> [tsub/alfred-datadog-workflow: A Alfred workflow to open Datadog pages](https://github.com/tsub/alfred-datadog-workflow)

Workflow のダウンロードリンクは[こちら](https://github.com/tsub/alfred-datadog-workflow/releases)から最新バージョンのものをどうぞ。

![image](https://gyazo.com/378dfd74e772c2d48776c5edd8ce6833.png)

<!--more-->

## Go を選んだ理由

Alfred Workflow は標準出力さえすればどの言語でも実装することができます。  
ただし、インストールしたユーザー側の実行環境でスクリプトを実行するのでユーザーの実行環境に影響されます。

実はわりと前に Alfred Workflow を書いていたことがありました。  
その時は Ruby で書いていて、大まかな機能までは作ったのですが、結局完成まではいけませんでした。

Ruby で書いていて困ったのが、ライブラリなどを利用する場合にワークフロー側にライブラリをバンドルするか、ユーザー側で gem install してもらう必要がありました。

その点、Go ならライブラリも含め 1 バイナリにまとめることができるのでその辺りをあまり気にしなくても良いです。

あとは単純に最近 Go を書いていたのが大きいです。

## 個人的に Alfred Workflow に向いていると思うところ

Alfred に限らず CLI や Chrome 拡張、Slack bot など作業の効率化・自動化などは様々な選択肢があると思います。

どのプラットフォームで作っても良いと思いますが、個人的に Alfred Workflow に向いているのは「何かのページの URL を開くこと」だと思います。

私が一番よく使う Workflow は AWS のサービスの URL を開く Workflow と、GitHub のリポジトリの URL を開く Workflow です。

* <i class="fa fa-github"></i> [gharlan/alfred-github-workflow: GitHub Workflow for Alfred 3](https://github.com/gharlan/alfred-github-workflow)
* <i class="fa fa-github"></i> [rkoval/alfred-aws-console-services-workflow: Very simple workflow to quickly open up AWS Console Services in your browser](https://github.com/rkoval/alfred-aws-console-services-workflow)

例えば後者の Workflow はこんな感じで AWS のサービスのページへ一発で飛ぶことができます。

![image](https://gyazo.com/9ac87e0e710401c5bfd222cf7f6a5338.png)

もちろん別の使い方をしている方も多いと思いますが、個人的にはこういった Workflow が一番便利に使えています。

ですので、今回も Datadog のページを単に開くだけ、という Workflow を作りました。

## 面白かったポイントなど

Alfred Workflow を作る上で面白かったポイントをいくつか紹介します。

### awgo が便利

今回は Alfred Workflow の開発にこちらのライブラリを使いました。

<i class="fa fa-github"></i> [deanishe/awgo: Go library for Alfred 3 workflows](https://github.com/deanishe/awgo)

Alfred Workflow は XML か JSON で標準出力さえすれば良いので、ライブラリはなくても実装可能です。

ただ、このライブラリを使うことでその辺りの実装を簡単にしてくれます。

例えば、以下のコードを書くだけで動かすことができます。

```go
package main

import "github.com/deanishe/awgo"

func run() {
    aw.NewItem("First result!")
    aw.SendFeedback()
}

func main() {
    aw.Run(run)
}
```

awgo が Alfred 用の自動的に JSON を組み立ててくれます。

その他、便利な Utility なども提供してくれて大変便利ですが今回はそこまで凝ったことはしなかったので使いませんでした。

### コードは書いても書かなくても良い

Alfred Workflow の面白いところとして、ほとんど自前で実装することもできますし、Alfred Workflow の機能を使って実装を省くことも可能です。

例えば、私が愛用している以下の Workflow はほとんど自前で実装しています。

<i class="fa fa-github"></i> [gharlan/alfred-github-workflow: GitHub Workflow for Alfred 3](https://github.com/gharlan/alfred-github-workflow)

中身を見てみると、色々な機能があるのに Alfred 側は非常にシンプルでほとんどの処理を Run Script の部分で自前で実装していることが分かります。

![image](https://gyazo.com/5abb5837caa844f1af0470e9f6e6a569.png)

逆に今回私が作った Workflow はなるべくコードを書かずに Alfred の機能を使って実装しました。

![image](https://gyazo.com/0bc6f22cd52e5824b27637580291ffbb.png)

認証の部分は少し複雑で、以下の Workflow を大いに参考にしました。

<i class="fa fa-github"></i> [KnVerey/alfred-datadog-dashes: List and filter your Datadog dashboards from Alfred3.](https://github.com/KnVerey/alfred-datadog-dashes)

Alfred の機能だけでこういった動きを作ることができます。

![image](https://gyazo.com/73ecb027cb71ef4219c821659910b751.gif)

### 認証情報の保管先

Alfred Workflow を作るときに API Key などをどこに保管するかはわりと問題になるようです。

ローカルファイルに書き込んでも良いですが、私は macOS の `security` コマンドを使いました。  
(こちらも <i class="fa fa-github"></i> [KnVerey/alfred-datadog-dashes](https://github.com/KnVerey/alfred-datadog-dashes) を参考にしました)

```shell
$ security add-generic-password -a $USER -s dd-api-key -w $1 -U
```

上記のコマンドを実行すれば dd-api-key というキーで maxOS のキーチェーンに API Key を保管できるようです。

また、保管した API Key の参照は以下のコマンドでできます。

```shell
$ security find-generic-password -a $USER -s dd-api-key -w
```

これで、Go で書いたコマンドを実行する際の引数として API Key などを渡してやれば良いだけです。

```bash
query=$1
apikey=$(security find-generic-password -a $USER -s dd-api-key -w)
appkey=$(security find-generic-password -a $USER -s dd-app-key -w)

./alfred-datadog-workflow --apikey=$apikey --appkey=$appkey dashboard
```

## 困ったところ

### 開発時の動作確認やリリース手順が面倒

良い方法があれば知りたいのですが、開発時に Go でコードを書いて Alfred Workflow の方にそれを毎回渡すのが面倒でした。

自分は Makefile に以下のように書いてビルドしたバイナリを Workflow のディレクトリにコピーしていました。  
(git 管理下には入れない)

```Makefile
build:
	go build -o build/$(PROJECT)
	cp assets/* build/
	cp build/$(PROJECT) ~/...(snip)/alfred/Alfred.alfredpreferences/workflows/user.workflow.XXXX/
.PHONY: build
```

同じくリリースについても、一度 Alfred 側にバイナリをコピーして、Alfred の GUI から Workflow の export をしてやる必要があります。

![image](https://gyazo.com/a6e16fdc45e3555c25270b3223123881.png)

これで、配布用の `.alfredworkflow` ファイルを作ることができるのでこれを GitHub releases に手動でアップロードしました。

![image](https://gyazo.com/392b199360054a8bb331e6a7a99ce83a.png)

そのため CI による自動化などはおそらくできないような気がします。

### Datadog の API クライアントライブラリのバグ

Datadog が公式で提供している Go のクライアントはあるのですが、Statsd の機能しか提供していないため今回は使えません。

<i class="fa fa-github"></i> [DataDog/datadog-go: go client library for datadog](https://github.com/DataDog/datadog-go)

ですので、今回は以下のサードパーティライブラリを使いました。

<i class="fa fa-github"></i> [zorkian/go-datadog-api: A Go implementation of the Datadog API.](https://github.com/zorkian/go-datadog-api)

ただ、こちらのライブラリで一点バグがあってそこで少しハマりました。

* Issue <i class="fa fa-github"></i> [strconv.ParseInt: parsing "null": invalid syntax when calling datadog.NewClient(apiKey, appKey).GetMonitors() · Issue #135 · zorkian/go-datadog-api](https://github.com/zorkian/go-datadog-api/issues/135)
* PR <i class="fa fa-github"></i> [Accept "null" in monitor NoDataTimeframe by dtan4 · Pull Request #129 · zorkian/go-datadog-api](https://github.com/zorkian/go-datadog-api/pull/129)

上記の内容に当たるバグです。  
API のレスポンスで `null` という文字列が返ってくることを考慮できていなかったようです。Terraform を経由して作ると発生するのかな。

最初は修正 PR を作ろとして PR を書いていたのですが、他の PR の 0 コメを参考にしようと見ていたら既に修正 PR が作成されていました。  
惜しい..

ですがまだマージされていなかったので、一旦は手元に pull してきたファイルを修正してビルドして使っています。

## まとめ

Alfred Workflow はかなりサクッと作れるし、Go との相性も良いと思いました。

普段仕事でこういうものが欲しいなぁと思ったらバシバシ作っていきたいと思います。
