+++
tags = ["AWS", "Alfred"]
date = "2019-10-06T14:35:00+09:00"
title = "「aws-vault loginでChromeのウィンドウをAWSアカウント毎に分離する」を Alfred 用に作った"
+++

<i class="fa fa-github"></i> [tsub/alfred\-aws\-vault\-workflow: A Alfred workflow to open the AWS Management Console with aws\-vault](https://github.com/tsub/alfred-aws-vault-workflow)

Chrome 版

![Features for Google Chrome](https://i.gyazo.com/33341687e0419d3863f913a00997744c.gif)

Firefox ([Multi-Account Container] extension) 版

![Features for Firefox](https://i.gyazo.com/a68e0d4cd6f9a80b659cfc1694cd85dd.gif)

aws-vault 自体今回初めて知ったのですが、以下の記事を読んで、複数の AWS アカウント使いには大変便利そうだったので Alfred 用のものをシュッと作りました。

[aws\-vault loginでChromeのウィンドウをAWSアカウント毎に分離する \- Qiita](https://qiita.com/minamijoyo/items/f3cbb003a34954a32970)

<!--more-->

## はじめに

まず最初に以下の記事をご覧ください。

[aws\-vault loginでChromeのウィンドウをAWSアカウント毎に分離する \- Qiita](https://qiita.com/minamijoyo/items/f3cbb003a34954a32970)

## 作った理由

自分は元々以下の Alfred Workflow を使って Alfred から AWS マネジメントコンソールを開いていたため、aws-vault も Alfred から使えるようにしたかったという理由です。

<i class="fa fa-github"></i> [rkoval/alfred-aws-console-services-workflow: Very simple workflow to quickly open up AWS Console Services in your browser](https://github.com/rkoval/alfred-aws-console-services-workflow)

しかし残念ながら今回作った [alfred-aws-vault-workflow] と [alfred-aws-console-services-workflow] の併用は厳しそうです。

[alfred-aws-vault-workflow] で AWS マネジメントコンソールにログインした後、[alfred-aws-console-services-workflow] を使うと、Chrome の場合はメインのウインドウで、Firefox の場合は Multi-Account Container でなく通常のウィンドウとして AWS マネジメントコンソールが開いてしまうためです。

これについては、今後あまりにも使い勝手が悪いようであれば、[alfred-aws-console-services-workflow] の機能を [alfred-aws-vault-workflow] に取り込む形でなんとかするかもしれません。

## 注意点

### aws-vault の PATH について

Alfred Workflow 内で Bash を動かした時の PATH の問題で、aws-vault は `/usr/local/bin/aws-vault` としてインストールされている前提 (ハードコーディングしている) になります。

Alfred の時点で macOS のみですし、大抵 Homebrew を使うと思うので大きな問題はないと思います。

Alfred Workflow の中に aws-vault のバイナリをパッケージングすることも考えましたが、アップデートへの追従が大変そうだったのでやめておきました。

### サポートしているブラウザについて

現時点では Google Chrome と Firefox のみになります。

元々 Chrome のみのつもりでしたが、過去に Firefox の [Multi-Account Container] extension を使ったことがあり、非常に好印象だったため、Firefox もサポートしています。

他のブラウザでも Chrome のプロファイルや Firefox の [Multi-Account Container] extension のような機能が CLI から使えれば仕組み的には対応可能だと思います。

### Firefox で使う場合

[Multi-Account Container] extension と [Open external links in a container] extension が必須になります。

[Open external links in a container] extension については、[Multi-Account Container] extension 単体では CLI から使えないため必要となります。

詳しくは以下の Issue をご覧ください。

<i class="fa fa-github"></i> [\[Feature Request\] Container cmdline option when opening URLs · Issue \#365 · mozilla/multi\-account\-containers](https://github.com/mozilla/multi-account-containers/issues/365)

[alfred-aws-vault-workflow]: https://github.com/tsub/alfred-aws-vault-workflow
[alfred-aws-console-services-workflow]: https://github.com/rkoval/alfred-aws-console-services-workflow
[Multi-Account Container]: https://addons.mozilla.org/firefox/addon/multi-account-containers/
[Open external links in a container]: https://addons.mozilla.org/firefox/addon/open-url-in-container/
