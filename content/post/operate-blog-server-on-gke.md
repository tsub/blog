+++
date = "2017-04-16T05:29:33Z"
tags = ["docker","GKE","kubernetes","hugo"]
title = "ブログをGKEでの運用に移行した"

+++

このブログはGitHub pagesを使って公開していたが、GKEに移行することにした。

[はてなブログからHugo on Github Pagesに移行しました](/post/created-blog-by-hugo/)

これを聞いて、99%の人が、HugoでHTMLファイルを生成して公開しているならわざわざサーバーなんて必要ないんじゃないか？金の無駄じゃないか？と思うかもしれない。

自分もそう思う。

今回GKEを使ったのはGKEとk8sでのコンテナ運用を経験したかったことが非常に大きい。

会社ではECSを本番運用しているが、ECSに比べてk8sの方が良さそうな雰囲気しかないのでGKEの方も触っておこうかと思って移行した。

また、今のところブログ以外に個人で運用しているWebサービス等はないため、ブログがちょうどいい題材だった。

<!--more-->

## GKEとは

GCP(Google Cloud Platform)で提供されている、k8s(kubernetes)のフルマネージドサービスである。

[Google Container Engine - Google Cloud Platform](https://cloud.google.com/container-engine/)

正式名称はGoogle Container Engineなのだが、Google Compute Engineと略称が被っているため、kubernetesの「K」を取って、「GKE」となったらしい。

今回、GKEを使いたいというよりはk8sを使いたいという目的の方が強かったため、[kube-aws](https://github.com/kubernetes-incubator/kube-aws)や[kops](https://github.com/kubernetes/kops)などでも良かったとは思うが、GCP自体にも興味があったためGKEを採用した。

ただし、一通り勉強しきってからの移行となると途中でモチベーションがなくなりそうになったため、k8sを軽く触れるようになったところで勢いで移行させた。

そのため、GCPの基礎自体ほとんど分かっていないまま作ってしまったのでこの辺りは後から改善していきたい。

### 構成

構成はだいたいこんな感じになった。

多分だいぶ簡略化されているのと、k8sちゃんと理解していないので間違っているかもしれない。

[後述する](#https対応)が、kube-legoというツールを使ってLoad Balancerに証明書を置いてhttps化しているため、blog Podは80番ポートのみ受け付けている。

![GKE blog structure](https://i.gyazo.com/6fd4002f6618be4442b0f213b7bb92f3.png)

## ブログのDockerイメージ

Hugoで生成したHTMLファイルをnginxで公開している。

Dockerfileは以下のような構成

```dockerfile
FROM nginx:alpine
LABEL maintainer "tsubasatakayama511@gmail.com"

COPY public /usr/share/nginx/html
COPY default.nginx /etc/nginx/conf.d/default.conf
```

また、別途Hugoをインストールしたイメージも作っている。

```dockerfile
FROM golang:1.8-alpine
LABEL maintainer "tsubasatakayama511@gmail.com"

ENV HUGO_DEPENDENCIES="git"

RUN apk add --update --no-cache \
        ${HUGO_DEPENDENCIES} && \
    go get -v github.com/spf13/hugo && \
    apk del --purge \
        ${HUGO_DEPENDENCIES}

COPY . /app
WORKDIR /app
RUN hugo

ENTRYPOINT ["hugo"]
```

Hugoのコンテナで生成したpublicディレクトリをdocker cpコマンドを使って取り出し、nginxのコンテナに含めている。

この辺りはよく見るやり方だと思う。

```bash
#!/bin/bash

set -x

docker build -t tsub/blog:hugo -f Dockerfile-hugo .
docker cp $(docker run -d tsub/blog:hugo):/app/public .
docker build -t tsub/blog .
```

ちなみに、Docker 17.05で追加されるmultiple stage buildという機能により、1つのDockerfile内で複数のFROMを書くことでファイルの受け渡しができるようになるらしい。

[Docker multi stage buildで変わるDockerfileの常識 - Qiita](http://qiita.com/minamijoyo/items/711704e85b45ff5d6405)

### 開発環境

開発環境も合わせてDockerizeしたので、ローカルにHugoをインストールする必要もない。

`$ docker-compose up -d`でコンテナを立ち上げ、localhost:1313にアクセスすればHugo serverにアクセスできるし、マウントしているのでファイルを書き換えたらすぐさま反映される。

```yaml
version: '3'
services:
  hugo:
    build:
      context: .
      dockerfile: Dockerfile-hugo
    command: [server, --bind=0.0.0.0]
    container_name: hugo
    image: tsub/blog:hugo
    ports:
      - 1313:1313
    volumes:
      - .:/app
```

### イメージのPush

最終的にできたnginxのイメージはDockerHubに置いている。

https://hub.docker.com/r/tsub/blog/

とりあえず公開した感じなのでdescriptionを何も書いてないし、後述のhttpsへのリダイレクトがあるためそのままは使えない。

イメージのPushは、複数のDockerfileを使ってビルドしている関係で、DockerHubのAutomated Buildを使えないのでCircleCIを使ってビルドしてPushしている。

```yaml
checkout:
  post:
    - git submodule sync
    - git submodule update --init --recursive

machine:
  timezone: Asia/Tokyo
  services:
    - docker

dependencies:
  override:
    - docker version
    - docker info
    - bin/build
    - docker images

test:
  override:
    - docker run -it tsub/blog echo 'Success to build tsub/blog image.'

deployment:
  release:
    tag: /[0-9]+(\.[0-9]+)*/
    commands:
      - docker login -e $DOCKER_EMAIL -u $DOCKER_USER -p $DOCKER_PASS
      - bin/deploy
      - bin/deploy $CIRCLE_TAG
```

tagを追加すると、DockerHubにそのタグのイメージがPushされる。

また、同時にlatestタグのイメージもPushするようにしている。

こちらは現在、CircleCI2.0に置き換える予定。

## kubectlが超良かった

ECSに比べて一番感動した部分はこれ。

[kubectl Overview | Kubernetes](https://kubernetes.io/docs/user-guide/kubectl-overview/)

ECSだと、[ECS CLI](https://github.com/aws/amazon-ecs-cli)というものがあるが、これに比べると非常に使い勝手がいい。

k8sの学習に[minikube](https://github.com/kubernetes/minikube)を使ってローカルにクラスターを立てて触っていたのだが、ここでも勿論kubectlが使えるし、GKEでクラスターを立てても[Google Cloud SDK](https://cloud.google.com/sdk/)を使って認証情報を取得すれば、同じようにkubectlを使うことができる。

ブログのコンテナを動かすときはこのファイル(`deployment.yml`)を置いて、`$ kubectl create -f deployment.yml`を実行すればk8s上でコンテナが動き始める。

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: blog
spec:
  replicas: 3
  template:
    metadata:
      labels:
        app: blog
    spec:
      containers:
      - image: tsub/blog
        name: blog
        ports:
        - containerPort: 80
```

`$ kubectl get pods`で実際に動いているPodの状態を確認できる。

```sh
$ kubectl get pods
NAME                    READY     STATUS    RESTARTS   AGE
blog-1654083343-bhfhz   1/1       Running   0          4d
blog-1654083343-r826c   1/1       Running   0          4d
blog-1654083343-sdx2v   1/1       Running   0          4d
```

また、コンテナを外部からアクセスさせたいときは同じように`$ kubectl create -f service.yaml`を実行してServiceを作ってやれば良い。

```yaml
apiVersion: v1
kind: Service
metadata:
  name: blog
spec:
  ports:
  - name: http
    port: 80
    targetPort: 80
  selector:
    app: blog
  type: NodePort
```

こちらも、`$ kubectl get services`でServiceの状態を確認できる。

```sh
$ kubectl get services
NAME            CLUSTER-IP    EXTERNAL-IP   PORT(S)          AGE
blog            10.3.247.61   <nodes>       80:30415/TCP     6d
kube-lego-gce   10.3.242.18   <nodes>       8080:32023/TCP   6d
kubernetes      10.3.240.1    <none>        443/TCP          6d
```

こんな感じで、kubectlは非常に直感的なコマンドを提供していて、使っていて気持ちがいい。

また、全ての操作がAPIでできるしyamlで定義できるところも良い。

### 新しいイメージのデプロイ

ブログのDockerイメージは前述の通りtagを追加すればCircleCIでビルドされ、DockerHubにPushされる。

そのため、デプロイする時はまずGitHubのリリースを作成すれば良い。

DockerHubにイメージがPushされたら、以下のコマンドを実行すれば、新しいイメージのReplicaSetsが作られて順にコンテナが置き換わっていく。

```
$ kubectl set image -f blog/deployment.yaml blog=tsub/blog:1.0.10
```

ここのデプロイフローは今後自動化したい。

## https対応

以前、GitHub pagesで公開していたときは、Cloudflareを使ってhttps化していたため、勿論https対応はしておきたい。

k8sはkube-legoというツールがあり、これを使うことで非常に簡単にLet's Encryptを用いた証明書の取得とhttps化をやってくれる。

[jetstack/kube-lego: Kube-Lego automatically requests certificates for Kubernetes Ingress resources from Let's Encrypt](https://github.com/jetstack/kube-lego)

[exampleのyaml](https://github.com/jetstack/kube-lego/tree/master/examples/gce/lego)をほとんどそのまま使えばk8s上にデプロイできる。

kube-legoがデプロイされた状態でk8sのIngressを作成すれば、kube-legoがLoad Balancerに証明書を設定してくれる。

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: blog
  annotations:
    kubernetes.io/ingress.global-static-ip-name: "kubernetes-ingress"
    kubernetes.io/ingress.class: "gce"
    kubernetes.io/tls-acme: "true"
spec:
  tls:
  - secretName: kubernetes-ingress-tls
    hosts:
    - blog.tsub.me
  rules:
  - host: blog.tsub.me
    http:
      paths:
      - path: /*
        backend:
          serviceName: blog
          servicePort: 80
```

1つハマったポイントとして、`spec.rules[0].http.paths[0].path`は`/*`と指定する必要があった。

[サンプル通りだと、`/`](https://github.com/jetstack/kube-lego/blob/master/examples/gce/echoserver/ingress-tls.yaml#L18)なのだがこれだとLoad Balancerのpathのルールがおかしくなり、バックエンドに接続できなかった。

PRが出ていたのでおそらく`/`は間違いなのだと思う。

[Change ingress paths from / to /* in gce example by ianmartorell · Pull Request #132 · jetstack/kube-lego](https://github.com/jetstack/kube-lego/pull/132)

また、他にハマったところとしてhttpでアクセスされた時にhttpsにリダクレクトする設定をnginxに書いたのだが、それによってLoad Balancerのヘルスチェックが通らなくなってしまった。

そのため、ヘルスチェック用のパスを用意し、そのパスのみリダイレクトを行わず、200 OKを返すようにした。

```nginx
...

  location / {
    if ($http_x_forwarded_proto != "https") {
      return 301 https://$host$request_uri;
    }

    root  /usr/share/nginx/html;
    index index.html index.htm;
  }

  location = /healthz {
    return 200 'ok';
  }

...
```

ただしIngressでヘルスチェックのパスを指定する方法がわからなかったため、k8sによって自動的に作成されたヘルスチェックのパスを後から変更することにした。

```sh
$ gcloud compute http-health-checks update <NAME> --request-path /healthz
```

## 移行した感想

とりあえず、会社で使っていたECSに比べてまだまだ細かいところまで触っていないのでk8sの方がいい！とは言えないが、個人的にはkubectlがあるだけでもかなり便利だし、内部はk8sなのでminikubeで個人のローカル環境立てたりとかできて、超良かった。

特にECSは内部の仕組みが公開されているわけではないので、k8sに比べるとコミュニティの勢いや盛り上がりに欠けるのかな、という印象。

ただし、そもそも静的サイトをわざわざ運用するメリットはないに等しいのでHugoからghostに移行するなども検討したい。

また、GCPはAWSより安い、というイメージが個人的にはあり、現時点の料金を見るとLoad BalancerはELBに比べた確かに安い気がするし、その他も多分安い

ただし、まだ1ヶ月も動かしていないので料金の話はまた別でしたい。

ちなみに自分がアカウントを作成した時は1年間の無料クーポンが3万円くらいもらえたのでとりあえずそれがなくなるまで運用してみて、高かったらまた別のプラットフォームに移行すると思う。
