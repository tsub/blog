+++
date = "2016-08-12T01:01:16+09:00"
tags = ["hugo"]
title = "はてなブログからHugo on Github Pagesに移行しました"

+++

はてなブログをやめて、Hugo on Github Pagesに移行しました。

といっても、走りだしのブログであまり記事は多くないんですが..

移行した理由は、以前のブログを構築した際に、調子に乗ってはてなブログProに登録して独自ドメインを使っていたのですが、思ったよりも記事を書かずお金がちょっと勿体無いなーと思い始めてきたのでGithub Pagesに移行しました。

<!--more-->

今までにOctopress、Jekyll、Middlemanと幾つか静的サイトジェネレータは使ったことがあるんですが、今回はHugoを使って構築しました。

個人的にはJekyllがGithub公式のため、いろいろと使い勝手が良かったんですが、テーマの導入が面倒なのが少し気になってました。

Jekyllの場合、テーマを導入するには基本的に他の方が作ったリポジトリをforkして、それを使う必要があります。

そのため、テーマを変えたくなった時に移行が大変です。
(軽く調べた程度なのでもしかしたらそんなこともないのかもしれませんが)

Hugoの場合はthemesディレクトリの中に各テーマのリポジトリをcloneしてくるだけでテーマを使えるので非常に簡単で使い勝手が良かったです。

今回使わせていただいたテーマは[angels-ladder](https://github.com/tanksuzuki/angels-ladder)というテーマです。
([forkして少しカスタマイズ](https://github.com/tsub/angels-ladder/tree/my-customized-theme)はしてますが)

デプロイはCircleCIを使って自動デプロイしています。

こちらの記事を参考にさせていただきました。

[HugoとCircleCIでGitHub PagesにBlogを公開してみた](http://hori-ryota.com/blog/create-blog-with-hugo-and-circleci/)

というわけで今後もよろしくお願いします
