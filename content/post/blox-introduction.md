+++
tags = [
  "Blox",
  "ECS",
  "docker",
  "AWS"
]
date = "2016-12-09T00:00:00+09:00"
title = "Blox Introduction"

+++

この記事は[Docker Advent Calendar 2016](http://qiita.com/advent-calendar/2016/docker)の9日目の記事です。

先日AWSのre:Invent 2016で[Blox](https://blox.github.io/)が発表されました。

BloxはEC2 Container Service(ECS)関連のオープンソースのツール群のことです。

そしてそのツールとは主にECSのカスタムスケジューラを指します

ECSはマネージドなスケジューラとマネージャを標準で備えていますが、Bloxはそれとは別に自分でホスティングする必要があります。

しかし、ECSに足りない機能を補ってくれるため導入するメリットは大きいでしょう。

[先日リリースされた、CloudWatchEventsのECSイベントストリーム](https://aws.amazon.com/jp/blogs/news/monitor-cluster-state-with-amazon-ecs-event-stream/)を利用することで、よりスムーズにECSのクラスタの状態を監視してカスタムスケジューラを作ることができるようになりました。

Bloxはこれを使った一例と言えます

この記事ではBloxについて試してみて分かった内容や所感について書いていきます

![Blox thumbnail](https://gyazo.com/4c00e85fca7b228d7aa0d5f1e6dd1d27.png)

<!--more-->

## Bloxの主な機能
Bloxが提供している機能は現在以下の2つです

* cluster-state-service
* daemon-scheduler

これらの機能をREST APIで扱うことができます。

どのような仕組みで動いているのかはAWS公式ブログにて分かりやすい図が載っていますのでまずは[こちら](https://aws.amazon.com/jp/blogs/compute/introducing-blox-from-amazon-ec2-container-service/)を読むことをおすすめします

この記事ではその辺りには特に触れません。主に使い方などをまとめました。

今後の追加機能に関しては[ロードマップ](https://github.com/blox/blox/issues?utf8=%E2%9C%93&q=is%3Aissue%20is%3Aopen%20label%3A%22roadmap%22)が作られていますのでそちらを参照してください

それではそれぞれの機能について見ていきます

## cluster-state-service

### ECSの課題
ECSには様々なAPIが用意されており、コンテナインスタンスやタスクの情報などを取得することができます。

しかし、痒いところには手が届きません。

例えば、あるクラスタで動いている特定のタスクの一覧を取得したいときにECSのAPIだとあるクラスタで動いているタスクの一覧を取得し、そこから取得したいタスクをフィルタリングする...のような手順が必要で面倒です。

### cluster-state-serviceが提供するもの

cluster-state-serviceはECSクラスタの状態を取得するためのものです。

冒頭でも書いたように、CloudWatchEventsのECSイベントストリームを利用できるようになりましたが、ECSのAPIからはそれらの情報は取得できません。

cluster-state-serviceはこのECSイベントストリームの情報を内部に保存し、外から参照できるREST APIを提供します。

cluster-state-serviceに関しては私はあまり理解できていませんが、クラスタ内の状態をより詳細に取得するための扱いやすいAPIというイメージです。

今のところGETするAPIしか提供していませんが、今後ECSのクラスタの状態を変更するためのAPIなども提供されるかもしれません。

また、後述のdaemon-schedulerでも内部的にcluster-state-serviceを使っているようです。

### APIドキュメント

APIのエンドポイントは特にドキュメントがなかったのでswaggerから読む必要があります。

[go-swagger](https://github.com/go-swagger/go-swagger)を使ってブラウザで表示すると読みやすいと思います

以下の場所に`swagger.json`が置いてあります

```sh
$ swagger serve cluster-state-service/handler/api/v1/swagger/swagger.json
```

## daemon-scheduler

### ECSの課題
ECSにはサービスという概念があります。

常駐しておきたいコンテナ群(タスク)をサービスとして動かすことで、希望するタスクの数をクラスタ内で一定に保つことができます。

これは非常に便利なのですが、クラスタ内の全コンテナインスタンスに対して1つずつタスクを実行させたい場合は使うことができません。

ポートを静的に指定すれば1コンテナインスタンスに1つずつタスクが実行されるのですが、「コンテナインスタンスの数 = タスクの数」を常に維持しなければいけないため、標準機能だけではできません。

また、ポートを静的に指定するというところもナンセンスです

### daemon-schedulerが提供するもの

daemon-schedulerはクラスタ内の全コンテナインスタンスに対して1つずつデーモンタスクを実行させるためのものです

例えば、dd-agentのような監視用コンテナを動かしたい場合、今まではUserdataを使ってインスタンスが立ち上がったタイミングで自分自身に対してECSのStartTaskを実行していましたが、daemon-schedulerを使えばその必要はなくなります。

クラスタ内に新たにコンテナインスタンスが立った場合、daemon-schedulerに設定しておいたTaskDefinitionを新たなコンテナインスタンスに対して勝手に実行してくれます。

### APIドキュメント

こちらもAPIのエンドポイントは特にドキュメントがなかったのでswaggerから読む必要があります。

以下の場所に`swagger.json`が置いてあります

```sh
$ swagger serve daemon-scheduler/generated/v1/swagger.json
```

## 試す
※ 残念ながら試せたのはdaemon-schedulerのみです

### セットアップ
Bloxが用意しているCloudFormationTemplateを使うとcluster-state-serviceとdaemon-schedulerが同時に動くようになっていますので同時にセットアップを行う形となります。

まずはBloxをAWSにデプロイします。

[ドキュメント](https://github.com/blox/blox/tree/master/deploy#aws-installation)に従ってやっていきます
今回は本番を想定してローカルではなくAWS上で動かします。

`/tmp/blox_parameters.json`を用意します

EcsAmiIdは2016/12/07時点で最新の[ECS Optimized AMI](http://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_container_instance.html)を使います。ちなみに東京リージョンです

```json
[
  { "ParameterKey": "EcsAmiId", "ParameterValue": "ami-9cd57ffd" },
  { "ParameterKey": "InstanceType", "ParameterValue": "t2.micro" },
  { "ParameterKey": "KeyName", "ParameterValue": "my-keypair" },
  { "ParameterKey": "EcsClusterName", "ParameterValue": "Blox" },
  { "ParameterKey": "QueueName", "ParameterValue": "blox_queue" },
  { "ParameterKey": "ApiStageName", "ParameterValue": "blox" }
]
```

それではデプロイします。

AWSの認証情報は適宜用意しておいてください。

```sh
$ git clone git@github.com:blox/blox.git
$ cd blox
$ aws --region ap-northeast-1 cloudformation create-stack \
      --stack-name BloxAws \
      --template-body file://./deploy/aws/conf/cloudformation_template.json \
      --capabilities CAPABILITY_NAMED_IAM \
      --parameters file:///tmp/blox_parameters.json
```

CloudFormation管理画面上でスタックのステータスがCREATE_COMPLETEになったらデプロイ完了です

![CloudFormation Status](https://gyazo.com/52ad79c7fcee9719044fecadc351ddd9.png)

Bloxのエンドポイントを取得します。

```sh
$ aws --region ap-northeast-1 cloudformation describe-stacks \
      --stack-name BloxAws \
      --query 'Stacks[0].Outputs[0].OutputValue' \
      --output text
https://kiwozuwzpf.execute-api.ap-northeast-1.amazonaws.com/blox
```

BloxのAPIを使うには認証が必要です。

BloxはAPI Gatewayを経由してAWSのIAM認証が可能です。

お使いのIAM Userに必要な権限がアタッチされていない場合は[こちら](https://github.com/blox/blox/tree/master/deploy#authentication)を参考に設定してください

認証にはAWS SignatureをサポートしているAPIクライアントの[Postman](https://www.getpostman.com/)を使うと便利です

![Authenticate with Postman](https://gyazo.com/2a443a422e660c8a205cfab41191072b.png)

APIのテストとしてdaemon-schedulerのエンドポイントである`/v1/ping`を叩いてみます

無事`200 OK`が返ってきました

![API Test](https://gyazo.com/6e9d14a41b2bf427308879fea4e8f00b.png)

これでBloxのセットアップは完了です

### cluster-state-service
Bloxが提供しているCloudFormationTemplateを読むと、cluster-state-serviceはELBと連携していないので、外部からのApiGateway経由ではアクセスできません。

おそらくクラスタ内部で扱うものだと思いますので今回は特に試しませんでした。

Internal ELBにも紐付いていないため、APIを使うとしたらBloxと同じタスク内で使うことになるかと思います。

### daemon-scheduler
まずはBloxクラスタとは別に任意のアプリケーションなどを動作させるためのクラスタを準備します。

[ecs-cli](https://github.com/aws/amazon-ecs-cli)を使うと楽です。

以下のようなyamlを用意します

検証用に用意しただけなので、どのようなコンテナでも構いません

```yaml
# docker-compose.yml
version: '2'
services:
  web:
    image: "nginx:alpine"
    ports:
      - "80:80"
```

以下のコマンドでクラスタを作成します

```sh
$ ecs-cli up --keypair my-keypair --capability-iam --size 1
```

クラスタが作成できたら、TaskDefinitionの登録と実行をします

```sh
$ ecs-cli compose up
```

無事、クラスタ内でタスクが実行されました

![Setup ECS cluster](https://gyazo.com/d4b8ce66e850b182d73f773e286d89ae.png)

さて、それではdaemon-schedulerを触っていきます。

Bloxのリポジトリ内には[APIを叩くための便利なクライアント](https://github.com/blox/blox/tree/dev/deploy/demo-cli)が用意されているのでそれを使います。

まずはEnvironmentを作成します

Environmentで定義するのは、どのクラスタでどのタスクを動かすか、です。

```sh
$ ./blox-create-environment.py --apigateway
== Blox Demo CLI - Create Blox Environment ==

- Enter CloudFormation stack name: BloxAws
- Enter Blox environment name: my-environment
- Enter ECS cluster name: tsub-sandbox
- Enter ECS task definition arn: ecscompose-ecs-cli


HTTP Response Code: 200
{
  "deploymentToken": "e22fadc7-3bbd-4de4-b28b-ecafae2c3826",
  "health": "healthy",
  "name": "my-environment",
  "instanceGroup": {
    "cluster": "arn:aws:ecs:ap-northeast-1:000000000001:cluster/tsub-sandbox"
  }
}
```

そして、先ほど作ったEnvironmentを使ってDeploymentを作成します。

Deploymentを作ることで対象のクラスタで実際にタスクが実行され始めます。

```sh
$ ./blox-create-deployment.py --apigateway
== Blox Demo CLI - Create Blox Deployment ==

- Enter CloudFormation stack name: BloxAws
- Enter Blox environment name: my-environment
- Enter Blox deployment token: e22fadc7-3bbd-4de4-b28b-ecafae2c3826


HTTP Response Code: 200
{
  "status": "pending",
  "environmentName": "tsub-environment",
  "id": "66fee44a-63c3-494e-aa34-476f14b4c4e3",
  "failedInstances": [],
  "taskDefinition": "arn:aws:ecs:ap-northeast-1:000000000001:task-definition/ecscompose-ecs-cli:1"
}
```

試しにコンテナインスタンスの数を増やしてみましょう。

![Increament cluster instance](https://gyazo.com/8e1085117f65077e197cf4a13e3c3e12.png)

新たに追加されたコンテナインスタンスでタスクが実行され始めました 👏

![daemon-scheduler DEMO](https://gyazo.com/87c17323e02353dca7716ad07cbaa1ed.png)

このように、特に何もしなくともコンテナインスタンスが追加されるたびにdaemon-schedulerが自動で対象のタスクを実行してくれるようになります。

## 所感
まさにECSの不満な部分を解決する救世主が現れた感じですね。

まだまだドキュメントや利用例が充実していないため、今回は手探りで使ってみたので間違ってるところなどあればご指摘いただければと思います。

特に使ってみた感触として、今回はBloxとアプリケーションは別々のクラスタで動かしましたが、Bloxを動かすクラスタはアプリケーションと同じクラスタを想定しているような気がしていて、その辺り引っかかっています。

今後の開発に期待ですね 😄
