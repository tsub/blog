+++
tags = ["Go", "AWS", "S3"]
date = "2017-09-05T22:30:00+09:00"
title = "Go で s3-edit という CLI アプリケーションを作った"

+++

最近 Rust を少し学んでいたが、難しくて少し挫折しかけたのと、結局仕事への導入を考えるなら Go のほうが既に書ける人が何人かいる、というのもあり Go を書き始めた。

手初めてに欲しい CLI アプリケーションがあったのでそれをサクッと Go で書いてみた。

<i class="fa fa-github"></i> [tsub/s3\-edit: Edit directly a file on Amazon S3](https://github.com/tsub/s3-edit)

<!--more-->

## モチベーション

仕事で S3 に環境変数を置いておいてそれを開発環境なり本番環境なりで使うことがあるのだが、そのファイルを編集する際に aws-cli を使って以下のコマンドを叩くのが面倒だった。

```sh
$ aws s3 cp s3://mybucket/myenvfile ./

# エディタでファイルを編集
$ nvim myenvfile

$ aws s3 cp myenvfile s3://mybucket/myenvfile
```

そこで、 S3 からファイルをダウンロードしてきてエディタを開いた後、編集してエディタを閉じたら S3 に再びアップロードしてくれる、というツールを作った。

```sh
$ s3-edit edit s3://mybucket/myenvfile
```

上記一コマンドだけで完結できる。

## cobra が良かった

多くの CLI アプリケーションで採用されている cobra というライブラリが非常に良かった。

<i class="fa fa-github"></i> [spf13/cobra: A Commander for modern Go CLI interactions](https://github.com/spf13/cobra)

公式の README にも書かれている通り、kubectl や hugo, docker など色々なツールで採用されている。

個人的にはこれらのツールのインターフェースは非常に使いやすいと感じていたため、それと全く同じような構成が cobra を使えば簡単に作れるのには驚いた。

ちょっと記述するだけで以下のようなインタフェースとヘルプメッセージなどを提供してくれる。

```sh
$ s3-edit --help
Edit directly a file on Amazon S3

Usage:
  s3-edit [flags]
  s3-edit [command]

Available Commands:
  edit        Edit directly a file on S3
  help        Help about any command
  version     Print the version of s3-edit

Flags:
  -h, --help      help for s3-edit
  -v, --version   print the version of s3-edit

Use "s3-edit [command] --help" for more information about a command.
```

今後も CLI アプリケーションを作る際は cobra を使っていきたいところ。

## 躓いたところ

S3 から受け取ったファイルの中身をどうやってローカルファイルに書き込むか、というところでわりと躓いた。

ドキュメントで言うと `s3.GetObjectOutput` の `Body` が `io.ReadCloser` 型のインターフェースを返すのだが、それをどうやってファイルに書き込めばいいのだろう？というところ。

http://docs.aws.amazon.com/sdk-for-go/api/service/s3/#GetObjectOutput

`io.ReadCloser` インターフェースは `Reader` と `Closer` インターフェースを持っていて、それぞれ `Read()` と `Close()` という関数が実装されていれば良い、というところまでは理解した。

https://golang.org/pkg/io/#ReadCloser

ただ、具体的に `s3.GetObjectOutput.Body` からどう値を取ればいいんだろうか、というところで困った。

調べていくと `bytes.Buffer` の `ReadFrom()` 関数の引数が `io.Reader` 型だったためそこに渡せば良さそう、というところに辿りついたのでやってみたらなんとかできた。

https://golang.org/pkg/bytes/#Buffer.ReadFrom

s3-edit の実装でいうとこの辺り。

```go
// https://github.com/tsub/s3-edit/blob/v0.0.5/cli/s3/object.go#L26-L31
	buf := new(bytes.Buffer)
	if _, err := buf.ReadFrom(res.Body); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	return buf.Bytes()
}
```

こういった、io の扱いとかが自分はまだ理解できていない。

以下の記事を読んだ感じでは、おそらく今回とった方法もあまり効率的ではない気もする。

[Golangでのstreamの扱い方を学ぶ \- Carpe Diem](http://christina04.hatenablog.com/entry/2017/01/06/190000)

## 楽しかったところ

Go のダックタイピングが個人的には楽しかった。

S3 周りのテストを書いていてモックを作る時、ああこうやって書けばいいのか、というのを理解した時の楽しさはやばかった。

s3-edit の実装でいうとこの辺り。

```go
// https://github.com/tsub/s3-edit/blob/v0.0.5/cli/s3/object_test.go#L12-L26
type mockedGetObject struct {
	s3iface.S3API
	Resp []byte
}

func (m *mockedGetObject) GetObject(input *s3.GetObjectInput) (*s3.GetObjectOutput, error) {
	pr, pw := io.Pipe()

	go func() {
		pw.Write(m.Resp)
		pw.Close()
	}()

	return &s3.GetObjectOutput{Body: pr}, nil
}
```

```go
// https://github.com/tsub/s3-edit/blob/v0.0.5/cli/s3/object.go#L15
func GetObject(svc s3iface.S3API, path Path) []byte {
```

関数の引数にインターフェースを受け取ることで、テスト側でそのインターフェースを拡張して引数として渡せば任意の処理ができてしまう。

最近仕事で Ruby を書いていて Dependency injection やダックタイピングなどを意識してコードを書いているが、Ruby ではいまいち納得感がない。

Go で書いたらそれらがすんなりと理解できた感じがある。

## リリースフロー

リリースフローは以下の手順で行うようにした。

1. GitHub で release を作る
2. dep で依存ライブラリをダウンロード
3. gox でクロスコンパイル (CircleCI)
4. 各バイナリを tar.gz に圧縮
5. CHECKSUMS ファイルを生成
6. ghr から 1 で作った release にバイナリをアップロード (CircleCI)

なお、CircleCI 内で扱う dep, gox, ghr は全て Docker でコンテナを動かす形にしてみた。

Go と直接関係ないが CircleCI では以下のところでハマった。

### `-v` オプションによるローカルファイルのマウントができない

CircleCI 2.0 ではコンテナ内にファイルをマウントする場合に `-v` オプションが使えない。

そのため、公式のドキュメントに書いてあるような方法をとる必要がある。

https://circleci.com/docs/2.0/building-docker-images/#mounting-folders

`docker create` でボリュームをマウントするためのコンテナを動かし、`docker cp` でそこにローカルファイルをコピーする。

その後、 `--volumes-from` オプションでコンテナ間でファイルをマウントすればようやく参照できる。

自分が書いた設定だと以下のようになった。

```yaml
# https://github.com/tsub/s3-edit/blob/v0.0.5/.circleci/config.yml#L18-L26
      - run: &create_dummy_container
          name: Create dummy container for mounting files and copy project files
          command: |
            docker create -v /go/src/github.com/tsub --name project busybox /bin/true
            docker cp $PWD project:/go/src/github.com/tsub/s3-edit
      - run:
          name: Vendoring go packages
          command: docker run --volumes-from project -w /go/src/github.com/tsub/s3-edit supinf/go-dep ensure
```

### Git tag でビルドをキックする

CircleCI 2.0 では Git tag によるビルドのキックは少し癖がある。

まず、Workflows を使う必要がある。

https://circleci.com/docs/2.0/workflows/#git-tag-job-execution

Workflows で `filters.tags.only` を指定しなければデフォルトでは Git tag を付けてもビルドがキックされない。

さらにハマりどころなのが、Workflows で複数の job を指定する際に tag によって制限したい job が依存している job にも `filters.tags.only` を指定する必要がある。

自分が書いた設定だと以下のようになった。

```yaml
# https://github.com/tsub/s3-edit/blob/v0.0.5/.circleci/config.yml#L78-L94
workflows:
  version: 2
  build_and_deploy:
    jobs:
      - build:
          filters:
            tags:
              only: /.*/
      - deploy:
          requires:
            - build
          filters:
            tags:
              only: /.*/
            branches:
              ignore: /.*/
```

なお、branch で動かしたくない場合は `fiters.branches.ignore` の指定も必要である。

Git tag が付いた時だけビルドを動かしたいだけなのにわりと書くことが多くややこしい。

## まとめ

とまあ、Go の話というより CircleCI の話になってしまったが、とりあえず作りたいものがサクッと作れたし、楽しく書けたので Go は今後もやっていく予定。

次は Go で何を作ろうか考え中...
