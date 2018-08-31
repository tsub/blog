+++
tags = ["Go", "CircleCI"]
date = 2018-08-30T05:33:00Z
title = "Go 1.11 の Modules (vgo) を CircleCI で使う"
+++

[個人プロジェクト](https://github.com/tsub/s3-edit)にて、先日リリースされた Go 1.11 の Modules (vgo) を使ってみました。

移行自体はスムーズにできたのですが、CircleCI でのキャッシュのやり方がそこそこ重要かも？と思ったので記事を書きました。

<!--more-->

## dep から Modules への移行

まずは dep で管理していた依存パッケージを Modules に移行します。

移行は簡単で、以下のコマンドを実行するだけです。

```sh
$ export GO111MODULE=on
$ go mod init
$ go mod download # go.sum を生成するため
```

これによって `go.mod` と `go.sum` が生成されるためこれらを git の管理下に入れれば OK です。

```sh
$ ls
go.mod  go.sum  Gopkg.lock  Gopkg.toml  main.go
```

後は dep 用のファイルを削除しましょう。

```sh
$ rm -f Gopkg.*
```

その他の詳しい使い方は今回は割愛します。

## CircleCI で Modules を使う

さて、本題の CircleCI 内で Modules を使う場合についてです。

[CircleCI の公式イメージ](https://hub.docker.com/r/circleci/golang/)で Go 1.11 がインストールされたイメージが公開されているのでこれを使います。

```sh
$ docker run -t circleci/golang:1.11.0 go version
go version go1.11 linux/amd64
```

`.circleci/config.yml` で `circleci/golang:1.11.0` を使い、`$GO111MODULE` に `on` を指定すれば良いです。

```yaml
version: 2
jobs:
  build:
    docker:
      - image: circleci/golang:1.11.0
        environment:
          GO111MODULE: "on"
    steps:
      - checkout
      - run:
          name: Run tests
          command: go test ./...
```

これで `$ go test ./...` 実行時に自動で依存パッケージをダウンロードしてきてくれます。

### Modules でダウンロードした依存パッケージをキャッシュする

ただし、上記の設定だけだと毎回依存パッケージをダウンロードしてくるので CI に時間がかかります。

そのため、CircleCI のキャッシュを使います。

```yaml
version: 2
jobs:
  build:
    docker:
      - image: circleci/golang:1.11.0
        environment:
          GO111MODULE: "on"
    steps:
      - checkout
      - restore_cache:
          name: Restore go modules cache
          keys:
            - mod-{{ .Environment.COMMON_CACHE_KEY }}-{{ checksum "go.mod" }}
      - run:
          name: Vendoring
          command: go mod download
      - save_cache:
          name: Save go modules cache
          key: mod-{{ .Environment.COMMON_CACHE_KEY }}-{{ checksum "go.mod" }}
          paths:
            - /go/pkg/mod/cache
      - run:
          name: Run tests
          command: go test ./...

```

Modules でダウンロードした依存パッケージはプロジェクトのディレクトリ内を見てもどこにもありません。

おもむろに `$GOPATH` 内をあさってみたところ、`$GOPATH/pkg/mod/cache` の中にダウンロードしてきた依存パッケージがありました。

これをキャッシュすれば良いです。

また、`go test ./...` で暗黙的にダウンロードする前に `go mod download` で明示的に依存パッケージをダウンロードするようにしてみました。

### Modules のベストプラクティスに乗っかる

公式の Wiki にリリースする前の準備として、ベストプラクティスが載ってました。

[Modules · golang/go Wiki](https://github.com/golang/go/wiki/Modules#how-to-prepare-for-a-release)

これによると、

* `go mod tidy` を実行して不要なパッケージの prune と必要なパッケージのダウンロードを行う
* `go test all` を実行して依存パッケージも含めた全パッケージのテストをする
* `go mod verify` を実行してダウンロードした依存パッケージが本当に正しいものか検証する

のが良いようです。

(ちなみにこれらは将来的に [`go release`](https://github.com/golang/go/issues/26420) コマンドによって自動化されるかもとのこと)

これに習って CircleCI の設定を書くと、以下のようになります。

```yaml
version: 2
jobs:
  build:
    docker: &docker
      - image: circleci/golang:1.11.0
        environment:
          GO111MODULE: "on"
    steps:
      - checkout
      - restore_cache: &restore_cache
          name: Restore go modules cache
          keys:
            - mod-{{ .Environment.COMMON_CACHE_KEY }}-{{ checksum "go.mod" }}
      - run: &vendoring
          name: Vendoring
          command: go mod download
      - save_cache: &save_cache
          name: Save go modules cache
          key: mod-{{ .Environment.COMMON_CACHE_KEY }}-{{ checksum "go.mod" }}
          paths:
            - /go/pkg/mod/cache
      - run:
          name: Run tests
          command: go test ./...

  deploy:
    docker: *docker
    steps:
      - checkout
      - restore_cache: *restore_cache
      - run: *vendoring
      - save_cache: *save_cache
      - run:
          name: Add missing and remove unused modules
          command: go mod tidy
      - run:
          name: Verify dependencies have expected content
          command: go mod verify
      - run:
          name: Run all tests
          command: go test all
      - deploy:
          name: Release
          command: curl -sL https://git.io/goreleaser | bash

workflows:
  version: 2
  build_and_deploy:
    jobs:
      - build:
          # ref: https://circleci.com/docs/2.0/workflows/#git-tag-job-execution
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

リリースに goreleaser を使っているのと、git のタグを打った時にリリースするというフローにしたため上記のようになっています。

`$ go mod tidy`, `$ go mod verify`, `$ go test all` はリリース前だけやれば良いかと思います (特に `$ go test all` は毎回やってると時間がかかるので)。
