+++
tags = ["terraform", "asdf"]
date = 2021-06-19T08:41:36Z
title = "Apple Silicon Mac で複数 Terraform バージョンを管理するために asdf-terraform-build を作った"
+++

[![tsub/asdf-terraform-build - GitHub](https://gh-card.dev/repos/tsub/asdf-terraform-build.svg?fullname=)](https://github.com/tsub/asdf-terraform-build)

<!--more-->

## 作った動機

今週から仕事で Apple Silicon Mac (M1 Mac) を使い始めました。

基本的には今まで使っていたツールは大体問題なく動いた (dotfiles の変更内容は[こちら](https://github.com/tsub/dotfiles/pull/2/files)) のですが、Terraform だけ少し困っていました。

仕事で Terraform を使っていると複数バージョンをインストールしたいことがあります。

複数の Terraform バージョンを管理する場合、asdf の [terraform プラグイン](https://github.com/asdf-community/asdf-hashicorp)を使うか、[tfenv](https://github.com/tfutils/tfenv) を使う場合が多いかと思います。

ただ、どちらの場合も Terraform のビルド済みバイナリをインストールする仕組みになっております。

実は 2021/06/19 現在、Terraform は Apple Silicon をサポートしたビルド済みバイナリを提供していないため、ソースからビルドする必要があります。

(詳しくは https://github.com/hashicorp/terraform/issues/27257 を参照)

そのため、複数バージョンの Terraform を管理する方法が事実上ありません。

そこで、ソースからビルドしてインストールする仕組みの asdf プラグインを今回作りました。

[![tsub/asdf-terraform-build - GitHub](https://gh-card.dev/repos/tsub/asdf-terraform-build.svg?fullname=)](https://github.com/tsub/asdf-terraform-build)

## メンテナンスの方針

前述の通り、Terraform が Apple Silicon 向けのビルド済みバイナリを提供していないことが原因のため、公式に提供されるようになったらこのプラグインはお役御免となります。

それまでの間一時的に使う用途ですので、最低限自分の環境で動くことしか確認しておらずちゃんと動くかは分かりません。

同じ問題で困っている方で、使ってみたけど期待通りに動かなかったなどあれば遠慮なく Issue/PR を作っていただければと思います。

Issue/PR を作るときは日本語で構いません。
