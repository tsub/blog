+++
tags = ["CircleCI"]
date = "2018-11-10T17:47:00+09:00"
title = "Circleci Orbs 入門"
+++

とうとう待望の CircleCI Orbs がリリースされたので一通り触ってみました。

[Announcing CircleCI Orbs and our new Technology Partner Program](https://circleci.com/blog/announcing-orbs-technology-partner-program/)

今回作ったサンプルは以下のリポジトリにありますので手っ取り早く知りたい人は以下のコードを見ると良いかと思います。

<i class="fa fa-github"></i> [tsub/circleci\-orbs\-sandbox](https://github.com/tsub/circleci-orbs-sandbox)

<!--more-->

## CircleCI Orbs とは

CircleCI の commands や jobs, executors をパッケージとして使い回すことのできる仕組みです。

公開されている Orb は Orbs Registry にあります。

[CircleCI Orb Registry](https://circleci.com/orbs/registry/)

公開されている Orb を使うには例えば以下のように書くことで自分の CircleCI のビルドで使うことができます。

```yaml
version: 2.1

orbs:
  hello: circleci/hello-build@0.0.5

workflows:
  "Hello Workflow":
    jobs:
      - hello/hello-build
```

基本的な使い方としては、以下で Orb の呼び出しと名前付けをし、

```yaml
orbs:
  hello: circleci/hello-build@0.0.5
```

使いたい箇所で `<自分で付けた Orb の名前>/<job 名>` などで使うことができます。

```
workflows:
  "Hello Workflow":
    jobs:
      - hello/hello-build
```

他にも Orb で commands や executors が提供されていれば同様に使うことができます。

詳しくは以下の公式チュートリアルをご覧ください。

[Using Orbs \- CircleCI](https://circleci.com/docs/2.0/using-orbs/#section=configuration)

## Orb を公開するには

さて、この記事の本題です。

Orbs は使うだけでなく、誰でも公開することができます。

以下の公式チュートリアルを見ればなんとなく分かります。

[Creating Orbs \- CircleCI](https://circleci.com/docs/2.0/creating-orbs/#section=configuration)

が、公式チュートリアルの説明が若干分かりづらかったと思ったので、(おそらく) 最小の公開手順を載せておきます。

1. [https://circleci.com/gh/organizations/<オーガニゼーション名>/settings#security](#) から CircleCI のオーガニゼーションの管理者がサードパーティ Orb の利用を許可する

    ![image](https://gyazo.com/c5416c34c5b55a92dd7c998c46c82760.png)

1. [circleci-cli](https://github.com/CircleCI-Public/circleci-cli) をインストール
    * すでにインストール済みの場合は `$ circleci update install` でアップデートしておくと良い
1. [こちらから](https://circleci.com/account/api) CircleCI の Personal API Token を生成
1. `$ circleci setup` を実行して Personal API Token を入力
1. `$ circleci namespace create <任意の Orb のネームスペース> <VCS プロパイダ名> <CircleCI のオーガニゼーション名>` を実行
    * 例: `$ circleci namespace create tsub github tsub`
1. 公開したい Orb の yml を用意

    ```yaml
    # orb.yml
    version: "2.1"
    description: "a sample orb"
    ```

1. `$ circleci orb publish orb.yml <Orb のネームスペース>/<任意の Orb 名>@<任意の Orb のバージョン>` を実行してリリース
    * 例: `$ circleci orb publish orb.yml tsub/sandbox@0.0.1`

ちなみに Orb 公開時のバージョンに `dev:<任意の名前>` を付けると開発用リリースとなり、同名のバージョンが 90 日以上リリースされなければ自動削除されます。

```
$ circleci orb publish src/hello-world/orb.yml tsub/hello-world@dev:test-branch
Orb `tsub/hello-world@dev:test-branch` was published.
Please note that this is an open orb and is world-readable.
Note that your dev label `dev:test-branch` can be overwritten by anyone in your organization.
Your dev orb will expire in 90 days unless a new version is published on the label `dev:test-branch`.
```

なお、現時点では公開した Orb は全てパブリックとなるので、注意が必要です。

> [WARNING] Orbs are always world-readable. All published orbs (production and development) can be read and used by anyone. They are not limited to just the members of your organization. In general, CircleCI strongly recommends that you do not put secrets or other sensitive variables into your configuration. Instead, use contexts or project environment variables and reference the names of those environment variables in your orbs.
>
> https://circleci.com/docs/2.0/creating-orbs/#publishing-an-orb

## Orb の開発・デプロイに便利な Orb

公式から Orb の開発やデプロイに便利に使える [circleci/orb-tools](https://circleci.com/orbs/registry/orb/circleci/orb-tools) という Orb が提供されています。

### Orb のテスト実行

例えば `test-in-builds` job を使えば自分で書いた Orb のローカル実行を CI することができます。

(ちなみに `test-in-builds` job と内部で使う `local-test-build` command だけ使い方が非常に分かりづらく、Orb のコードを読み解く必要がありました)

以下の YAML を用意します。

```yaml
# .circleci/config.yml
version: "2.1"

orbs:
  orb-tools: circleci/orb-tools@2.0.2

workflows:
  version: "2"

  test_orb:
    jobs:
      - orb-tools/test-in-builds:
          orb-location: src/hello-world/orb.yml
          orb-name: hello-world
          test-steps:
            - orb-tools/local-test-build:
                test-config-location: src/hello-world/test.yml
```

```yaml
# src/hello-world/orb.yml
version: "2.1"
description: "a sample orb"

commands:
  hello:
    steps:
      - run:
          name: Echo "hello"
          command: echo hello

  world:
    steps:
      - run:
          name: Echo "world"
          command: echo world

executors:
  default:
    docker:
      - image: busybox

jobs:
  hello_world:
    executor: default
    steps:
      - hello
      - world
```

```yaml
# src/hello-world/test.yml
version: "2.1"

jobs:
  build:
    executor: hello-world/default
    steps:
      - hello-world/hello
      - hello-world/world
```

すると、CI で `src/hello-world/orb.yml` を `$ circleci local execute` を使ってローカル実行してくれます。

> [![image](https://gyazo.com/b7b861910a880d021fe6ced5840bd447.png)](https://gyazo.com/b7b861910a880d021fe6ced5840bd447.png)
>
> https://circleci.com/gh/tsub/circleci-orbs-sandbox/36

注意点としては、`$ circleci local execute` コマンドなので、Workflows には対応していないのと、job 名はデフォルトの `build` 固定になっています。

> **Note**: This command will only run a single job, it does not run a workflow.
>
> https://circleci.com/docs/2.0/local-cli/#run-a-job-in-a-container-on-the-local-machine

```
$ circleci local execute --help
...
      --job string            job to be executed (default "build")
...
```

そのため、現時点では Orb で定義した jobs のテストはできず、commands や executors しかテストできません。

job 名の指定にも対応してもらえるとありがたいですね (`circleci/orb-tools` のリポジトリがどこにあるかわからず PR 投げれなかった)。

### Orb の自動デプロイ

他にも、`publish` や `increment` という job が提供されていて、これを使うことで Orb の自動デプロイを簡単に実装することができます。

先ほどの YAML を使いまわしつつ、`.circleci/config.yml` を以下のように書き換えます。

```yaml
# .circleci/config.yml
version: "2.1"

orbs:
  orb-tools: circleci/orb-tools@2.0.2
  slack: circleci/slack@0.1.1

executors:
  default:
    docker:
      - image: circleci/buildpack-deps

jobs:
  send-approval-link:
    executor: default
    steps:
      - slack/notify:
          message: |
            Please check and approve Job to deploy.
            https://circleci.com/workflow-run/${CIRCLE_WORKFLOW_ID}

workflows:
  version: "2"

  build_test_deploy:
    jobs:
      - orb-tools/test-in-builds:
          orb-location: src/hello-world/orb.yml
          orb-name: hello-world
          test-steps:
            - orb-tools/local-test-build:
                test-config-location: src/hello-world/test.yml

      - orb-tools/publish:
          requires:
            - orb-tools/test-in-builds
          filters:
            branches:
              ignore: master
          orb-path: src/hello-world/orb.yml
          orb-ref: tsub/hello-world@dev:${CIRCLE_BRANCH}
          publish-token-variable: "$ORB_PUBLISHING_TOKEN"

      - send-approval-link:
          requires:
            - orb-tools/test-in-builds
          filters:
            branches:
              only: master

      - manual-approval:
          type: approval
          requires:
            - send-approval-link
          filters:
            branches:
              only: master

      - orb-tools/increment:
          requires:
            - manual-approval
          filters:
            branches:
              only: master
          orb-path: src/hello-world/orb.yml
          orb-ref: tsub/hello-world
          segment: patch
          publish-token-variable: "$ORB_PUBLISHING_TOKEN"
```

ついでに、デプロイ前に Manual Approval と、Slack 通知もやっています。

Slack 通知も Orb として配布されているものを使うことで簡単に利用できます。

これで、master ブランチにコミットすると、自動で Slack に Workflow のリンクが飛び、Approve すれば Orb が自動デプロイされます。

[![image](https://gyazo.com/34205c870203a322991f0e6d2a4f3fb2.png)](https://gyazo.com/34205c870203a322991f0e6d2a4f3fb2.png)

[![image](https://gyazo.com/31b98eff308522645cb4c55f5b429a1a.png)](https://gyazo.com/31b98eff308522645cb4c55f5b429a1a.png)

[![image](https://gyazo.com/5e0131bedf463c3038b92b4989beae87.png)](https://gyazo.com/5e0131bedf463c3038b92b4989beae87.png)

ちなみに、`increment` job で使われている `$ circleci orb publish increment` コマンドを使うことで、セマンティックバージョニングに基づいて自動でバージョンをインクリメントしてリリースしてくれます。

```sh
$ circleci orb publish increment --help
Increment a released version of an orb.
Please note that at this time all orbs incremented within the registry are world-readable.

Example: 'circleci orb publish increment foo/orb.yml foo/bar minor' => foo/bar@1.1.0


Usage:
  circleci orb publish increment <path> <namespace>/<orb> <segment> [flags]
Aliases:
  increment, inc

Args:
  <path>      The path to your orb (use "-" for STDIN)
    <segment>   "major"|"minor"|"patch"


Flags:
  -h, --help   help for increment

Global Flags:
      --host string    URL to your CircleCI host (default "https://circleci.com")
      --token string   your token for using CircleCI
```

## まとめ

CircleCI Orbs を一通り試してみましたが、非常に夢のある機能だと思うので、今後どんどん便利な Orb が増えていくと良いですね。

自分も仕事でよく同じような CircleCI の設定ファイルを書くことが多かったので、Orb にして記述量を減らすことができると便利だなぁと思います。

もちろん、Orb は現時点では全てパブリックになってしまいますので、汎用的な Orb にする必要があることは注意です。
