+++
tags = ["AWS", "イベントレポート"]
date = 2018-03-17T06:16:55Z
title = "JAWS DAYS 2018 に行ってきた"
+++

社内勉強会の準備などで忙しく、レポートを書くのが遅れてしまいましたが、先週の 03/10 (土) に [JAWS DAYS 2018](https://jawsdays2018.jaws-ug.jp/) へ行ってきました。

![image](https://gyazo.com/5dafdbb66c5c6fd5a78aafeb83bd49c8.png)

今回が初参加でしたが、AWS ユーザーグループのお祭りという感じですごく盛り上がっていて楽しいイベントでした。

会社の同僚も 4 人ぐらい参加してました。

自分が参加したセッションと聞いた感想やメモをつらつら書いていきます。

(ただし Keynote は省きます)

<!--more-->

## コンテナでウェイウェイ（仮）

(スライドは見つからなかった。[公式のセッションページはこちら](https://jawsdays2018.jaws-ug.jp/session/756/))

このセッションは前半後半でそれぞれ違う発表でした。

**前半**

* AWS の人から見た Fargate と Lambda の使い分けの視点を聞けたのは良かった
    * Fargate では難しいもの
        * Windows Container
        * GPU
        * docker exec
        * Spot や RI
        * Task のメトリクス
    * Lambda を使った方が良い場合
        * イベントドリブン
        * ms単位
        * ランタイム管理をしたくない
        * 分散バッチコンピューティング
* 最近 EC2 や ECS, Fargate の SLA が 99.99% に引き上げられたとのこと

**後半**

* Segment.io 社の大規模な ECS 利用状況を聞けたのは良かった
    * そのぐらいの規模でも ECS で運用できるというのが知れて安心した
* Segment.io の ECS 利用状況が凄まじい
    * 秒間40万リクエスト、15000個のコンテナ
    * インスタンスは c5.9xlarge
* ECS Optimized AMI を使ってないのはびっくり
    * Ubuntu 16.04 の Systemd で Docker Daemon を動かし、ecs-agent を動かしているらしい
* cluster の分け方は少し参考になった
    * common という cluster を用意しているらしい。megapool と呼んでいた
    * 雑にコンテナを動かす場合とかは common cluster で動かすのかな？
* オートスケールのポリシーが聞けたのも良かった
    * Service は CPU かメモリが 90% を超えたらスケールアウト、70 % を切ったらスケールダウン
    * インスタンスは reservation 値を元にスケール
* ECS 周りのツールでいくつか知らないものもあったので聞けて良かった
    * https://github.com/segmentio/ecs-logs
    * https://github.com/stripe/veneur
    * veneur の方は DogStatsD へメトリクスを送るためのグローバルなアグリゲーターらしい。大規模なアプリケーションになってくると必要になりそう

## ユーザー企業におけるサーバレスシステムへの移行

<script async class="speakerdeck-embed" data-id="12e6e70cf25a4486967aebc2456e5436" data-ratio="1.33333333333333" src="//speakerdeck.com/assets/embed.js"></script>

* 組織の状況やユースケースにサーバーレスアーキテクチャがぴったりハマっていて技術選定のセンスがすごいと思った
* 以前はサーバーを設置するために土地や建屋、非常電源なども管理していたとのこと。すごい..
    * 今はクラウドにしたことでその辺りの管理コストが減った。サーバーレスなアーキテクチャにしたことでサーバーの管理コストも減った
* AWS のサービス周りで色々な知見を聞けたのは良かった
    * S3 はデータを大量に移動させようとすると一部移動されないものがあるらしい。移動されなかったデータはポーリングして拾っているとのこと
    * S3 は同じようなファイル名にすると検索が遅いので、ファイル名の先頭にランダムな値を付けて検索を早くしたとのこと
    * DynamoDB で Lambda で並列処理をすると書き込みキャパシティが足りなくなったので Lambda の同時実行数を制限してキャパシティを超えないようにしたとのこと
* sam-local などを動かしたら開発マシンのスペックが足りない人が増えたので、Cloud9 を使い始めたとのこと

## コンテナを守る技術 2018

<script async class="speakerdeck-embed" data-id="52ba967a84094efdb39fc582318a28f5" data-ratio="1.77777777777778" src="//speakerdeck.com/assets/embed.js"></script>

* 全体的に知らない情報が多かった
    * コンテナでここまでセキュリティを意識している事例はあまりないんじゃないだろうか..すごく良い内容だった
* IAM Role のポリシーに関しては耳が痛い..最小限にすべきなところをついつい面倒臭がって FullAccess とかを付けてしまいがち
* https://github.com/docker/docker-bench-security 知らなかった
    * ホストのセキュリティ状況をチェックできるスクリプト
    * 自動化するなら Lambda で SSM の RunCmd を叩き、実行する ログは CloudWatch Logs に送り、CloudWatch からアラートを送るだけなので簡単
* Docker イメージのセキュリティチェックとかはやりたいなと思っていた。具体的なツール名も知れて良かった
    * https://github.com/coreos/clair
    * https://github.com/eliasgranderubio/dagda
* NeuVector のデモすごかった
    * アプリケーションが利用する正常な通信径路を設定しておくと、想定外な通信が走った場合は警告が出て画面上で通信を遮断できる
    * NeuVector で十分すごいのに aqua がおすすめらしい。aqua のデモも見たかった
* 12 factor app に従ってなんでも環境変数で渡しがちだけど、DB のパスワードなどを環境変数で渡すと色々なところで見えてしまう
    * SSM のパラメータストアを使うのがおすすめらしい

## Reusable serverless components accross Projects via Terraform

<iframe src="//www.slideshare.net/slideshow/embed_code/key/wrvsVW81dgoWbp" width="595" height="485" frameborder="0" marginwidth="0" marginheight="0" scrolling="no" style="border:1px solid #CCC; border-width:1px; margin-bottom:5px; max-width: 100%;" allowfullscreen> </iframe> <div style="margin-bottom:5px"> <strong> <a href="//www.slideshare.net/dav009/terraforming-90492064" title="Terraforming " target="_blank">Terraforming </a> </strong> from <strong><a href="https://www.slideshare.net/dav009" target="_blank">David Przybilla</a></strong> </div>

* 会社で Terraform を使っているので参考になった
* module 化によって中身が隠蔽されたので覚えることが少なくなったとのこと
* terraform plan の結果が Slack に届き、Approve したら terraform apply されるらしい
    * Terraform のデプロイパイプラインは正直整えてないので、こういうの自分もやりたい
* `.tfversion` というファイルが見慣れなかったので調べたけど、自前？
    * 調べてたら https://github.com/kamatama41/tfenv というツールを見つけた。xxenv 系のいつものやつっぽい

## LambdaとStepFunctionsを使った新しい負荷試験のカタチ

<script async class="speakerdeck-embed" data-id="01c3d4b2311e45f1a88a3f2d17091f75" data-ratio="1.77777777777778" src="//speakerdeck.com/assets/embed.js"></script>

* 負荷試験をやりたいけどまだやれてないので参考になればと思って聞いた
* 何より驚いたのがコストの部分。秒間 200 万アクセスを出せるのにたったの $1.251 しかかからないらしい
* API Gateway からのリクエストを受けて動的に StepFunctions のステートマシンを作っているのは面白かった
* Fargate を使うとオーバーヘッドがあって攻撃タイミングがずれるとのこと。ここは盲点だった
* OSS 化は期待

## 全体的な感想

* 知らない情報がたくさん聞けたので参加して良かった
* ただし丸一日イベントはやっぱり疲れる。会場が自宅から遠く、朝も早いのでちょっと辛かった
* 基本的にコンテナの話を聞きたかったけど、あまり多くはなかった。コンテナよりもサーバーレスが盛り上がっている感じだろうか
