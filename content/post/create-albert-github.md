+++
tags = ["Albert", "Python"]
date = "2018-10-28T18:35:00+09:00"
title = "Albert で GitHub リポジトリを開ける拡張を作った"
+++

先日プライベートの開発マシンを Linux にしたのですが、macOS の時に一番重宝していたものがなにかというと、実は [Alfred](https://www.alfredapp.com/) だったことに気づきました。

Alfred がないとストレスフルです。

ただ Linux には Alternative Alfred がいくつかあり、その中でも Albert が比較的良さそうだったので Albert を使っていますが、Alfred で言う Workflow にあたるものが全然充実していませんでした。

特に Alfred から GitHub を開く操作が一番多い気がするので、まずはそれを Albert でもできるようにするために、今回拡張を作りました。

<i class="fa fa-github"></i> [tsub/albert\-github: Open GitHub repository in browser with Albert](https://github.com/tsub/albert-github)

![image](https://gyazo.com/fff7125ea22e33c863f6fd535d7f2b8b.png)

<!--more-->

## Albert の拡張を作る方法

Albert で自作の拡張を作るには Python のコードを指定されたディレクトリ内に配置すれば OK です。

Albert が読み込んでくれるディレクトリはドキュメントに書かれています。

> * ~/.local/share/albert/org.albert.extension.python/modules
> * /usr/local/share/albert/org.albert.extension.python/modules
> * /usr/share/albert/org.albert.extension.python/modules
>
> https://albertlauncher.github.io/docs/extensions/python/#deployment

ここに直接 Python のファイルを `GitHub.py` のように置いてもいいですし、`GitHub/__init__.py` のようにディレクトリを切ることもできます。

```sh
$ ls -l ~/.local/share/albert/org.albert.extension.python/modules/GitHub/
.rw-r--r-- 5.1k tsub 28 Oct 17:26 __init__.py
drwxr-xr-x    - tsub 28 Oct 17:26 __pycache__
.rw-r--r--  898 tsub 27 Oct 18:08 GitHub.svg
```

アイコンファイルも一緒に置くことも考えると上記のようにディレクトリを切って置くと良いと思います。

後は Albert が用意している Python モジュールを使って実装します。

以下のドキュメントに使える関数などが定義されています。

https://albertlauncher.github.io/docs/extensions/python/#extension-interface-01

ただこれだけだと分からないので、自分は公式拡張のコードを参考にしました。

<i class="fa fa-github"></i> [albertlauncher/python: A repository for the official Python extensions](https://github.com/albertlauncher/python)

ちなみに、Alfred の場合は標準出力さえ出せればどんな言語で実装しても良かったのですが、Albert は Python のみのようです。

過去に Albert にも External plugin というものがあり、シェルスクリプトで書けたようなのですが、今は deprecated になっていました。

<i class="fa fa-github"></i> [albertlauncher/external: \[deprecated\] A repository for external plugins](https://github.com/albertlauncher/external)

あと、Alfred のようなリッチな Workflow 開発環境はないので、Albert の場合はすべてコードで書かないといけません。

![image](https://gyazo.com/0bc6f22cd52e5824b27637580291ffbb.png)

## 今後

Alfred で重宝していた Workflow は他にもいくつかありますのでこれらと同じような操作を Albert でできるように拡張を作っていきたいと思います。

* <i class="fa fa-github"></i> [rkoval/alfred-aws-console-services-workflow: Very simple workflow to quickly open up AWS Console Services in your browser](https://github.com/rkoval/alfred-aws-console-services-workflow)
* <i class="fa fa-github"></i> [tsub/alfred-datadog-workflow: A Alfred workflow to open Datadog pages](https://github.com/tsub/alfred-datadog-workflow)

なお今回作った GitHub の拡張自体もまだ作りきれてない部分があり、キャッシュの更新などの実装が残っています。

現状一度リポジトリを取得するとそれ以降はキャッシュを使うので新しいリポジトリが増えても反映されません。

そのためキャッシュの更新をする必要があるのですが、Albert で非同期に処理を書けるのかが現状不明です。

基本的に Albert で一文字タイプするたびに 1 回 Python スクリプトが実行されるのですが、表示したい内容を `return` して実行終了、というようなサイクルになっています。

そのため、リポジトリ一覧を表示しながら裏でキャッシュを更新し、更に表示も更新するというようなことができなさそうな気がしています。

キャッシュの更新の他にも、初回表示時にリポジトリの取得が遅いという問題もあるのですが、これもページネーションしつつ取得できたものから順次表示などできるのか不明です。

そこら辺はもう少し調べてみる予定です。
