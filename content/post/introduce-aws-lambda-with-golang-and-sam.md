+++
tags = ["AWS Lambda", "Go", "SAM", "CloudFormation"]
date = "2018-01-31T23:15:00+09:00"
title = "AWS Lamabda with Golang と SAM に入門した"
+++

先日 AWS Lambda の Golang サポートがリリースされました。

[Announcing Go Support for AWS Lambda | AWS Compute Blog](https://aws.amazon.com/jp/blogs/compute/announcing-go-support-for-aws-lambda/)

今回は AWS Lambda を Golang で書きつつ、[SAM](https://github.com/awslabs/serverless-application-model) へも入門したのでその辺りの知見とか作ったものについて紹介します。

<!--more-->

## 作ったもの

手始めに、Qiita:Team のテンプレートを元に決まった時刻に自動的に記事を作ってくれる function を書きました。

<i class="fa fa-github"></i> [tsub/serverless-qiita-team-template: [under development] Create a Qiita:Team new post from templates](https://github.com/tsub/serverless-qiita-team-template)

`under development` と書いてありますが、一応動くものになってはいます。

ただ、主に社内で使うために作ったのであまり汎用的に作れてはいません。

弊社では技術コミュニティ的なものがいくつかあり、週に一回 Qiita:Team に記事を作り、事前に各自トピックを書いて、時間になったら集まって順番に発表しています。

詳しくは会社の技術ブログにて紹介されています。

[『ff_rookies.*』という社内新卒エンジニアの技術共有会をやってます - Feedforce Developer Blog](http://developer.feedforce.jp/entry/2017/12/12/213335)

この記事を定期的に作る、という作業を自動化するために今回 Lambda function を作りました。

仕組みは簡単で、CloudWatch Events のスケジュール実行で指定した時刻に AWS Lambda を実行し、Qiita API を叩いてテンプレートを元に記事を投稿するだけです。

```
+-------------------+     +------------+     +------------+
| CloudWatch Events | --> | AWS Lambda | --> | Qiita:Team |
+-------------------+     +------------+     +------------+
```

## AWS Lambda を Go で書いてみて

今回は Event から値を受け取って何かに使う、というような AWS Lambda らしいことをしていないため特に困ることはありませんでした。

ハンドラー部分の処理も以下のように `HandleRequest` 関数内では普通に Go のコードを実行しているだけです。

```golang
func HandleRequest() (string, error) {
    token, err := decrypt(os.Getenv("QIITA_ACCESS_TOKEN"))
    if err != nil {
      return "", err
    }
    team, err := decrypt(os.Getenv("QIITA_TEAM_NAME"))
    if err != nil {
      return "", err
    }
    templateID, err := decrypt(os.Getenv("QIITA_TEAM_TEMPLATE_ID"))
    if err != nil {
      return "", err
    }

    client := &Client{
      Token:      token,
      Team:       team,
      TemplateID: templateID,
    }

    template, err := client.GetTemplate()
    if err != nil {
      return "", err
    }

    url, err := client.CreateItem(template.ExpandedTitle, template.ExpandedBody, template.ExpandedTags)
    if err != nil {
      return "", err
    }

    return fmt.Sprintf("URL: %s", url), nil
}

func main() {
	  lambda.Start(HandleRequest)
}
```

今回 Go で書いてみた感想としては Node.js と違って同期的なコードなので普通に手続き型で書けるし、非同期処理を使う場合も goroutine を使うのでかなり簡単だし (今回は使ってない)、他の Lambda で使える静的型付け言語と比べると比較的簡単に始められるし、かなり AWS Lambda とマッチしていると思っています。

今までも [apex](https://github.com/apex/ape://github.com/apex/apex) や [aws-lambda-go-shim](https://github.com/eawsy/aws-lambda-go-shim) というツールを使えば AWS Lambda で Go を使うことはできましたが、公式のサポートでもないのでどうにも会社で使う気にはなれませんでした..

ただ、今回 SAM を選んだ理由は [Serverless Application Repository](https://aws.amazon.com/jp/serverless/serverlessrepo/) が先日の Re:Invent 2017 で発表されたためです。

Serverless Application Repository はまだプレビュー版のみの提供となりますが、SAM で定義した Lambda function なら公開でき、他ユーザーの導入が簡単になるらしいです。

今まで [Serverless Framework を使って function を作ったこと](https://github.com/tsub/circleci-build-trigge://github.com/tsub/circleci-build-trigger)はありますが、他ユーザーが利用するときのセットアップなどは少々手間がかかりました。

その辺が Deploy to Heroku Button みたいに簡単にデプロイ出来るようになれば、OSS として公開するようなツールは SAM を使うのが主流になっていきそうですね。

## 今回得た知見など

### AWS SAM (CFn) で環境変数を使う

SAM、というか CFn の話になりますが、開発者によって異なる値など、環境変数を使いたい場合 `Parameters` セクションを使うと実現できました。

以下のように `Parameters` セクションをトップレベルで指定しておき、参照したい箇所で `!Ref <パラメーター名>` で参照します。

```yaml
...

Parameters:
  QiitaAccessToken:
    Type: String
  QiitaTeamName:
    Type: String
  QiitaTeamTemplateId:
    Type: String
  KmsKeyId:
    Type: String
  ScheduleExpression:
    Type: String

Resources:
  App:
    ...
    Properties:
      ...
      Environment:
        Variables:
          QIITA_ACCESS_TOKEN: !Ref QiitaAccessToken
          QIITA_TEAM_NAME: !Ref QiitaTeamName
          QIITA_TEAM_TEMPLATE_ID: !Ref QiitaTeamTemplateId
```

そして、パッケージングした CFn テンプレートをデプロイするときにオプションで渡すことができます。

```
$ aws cloudformation deploy \
    --template-file .template-output.yml \
    --stack-name stack-name \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides \
        QiitaAccessToken="${QIITA_ACCESS_TOKEN}" \
        QiitaTeamName="${QIITA_TEAM_NAME}" \
        QiitaTeamTemplateId="${QIITA_TEAM_TEMPLATE_ID}" \
        KmsKeyId="${KMS_KEY_ID}" \
        ScheduleExpression="${SCHEDULE_EXPRESSION}"
```

### KMS で環境変数を暗号化/復号化する

AWS Lambda に環境変数を設定した時、会社のアカウントなど自分以外の人も環境変数を閲覧できてしまうため、今回は KMS を用いて環境変数を暗号化しました。

今まで AWS Lambda 自体は Serverless Framework を使って利用していましたが、意識高く KMS で暗号化したのは初めてでした。

ちなみに AWS Lambda の Encryption helper を使えば、実装が不要で楽になるみたいですが CFn や SAM では対応していないようだったので、自前で暗号化/復号化を行いました。  
設定自体はコンソールからできるようです。

![image](https://gyazo.com/4dfeaef5049867ceb590bf35b787b944.png)

暗号化は `Makefile` の中でやりました。

```makefile
define encrypt
  aws kms encrypt \
    --key-id "${KMS_KEY_ID}" \
    --query CiphertextBlob \
    --output text \
    --plaintext $(1)
endef

deploy:
  aws cloudformation package \
    --template-file template.yml \
    --s3-bucket $(PROJECT) \
    --output-template-file .template-output.yml
  aws cloudformation deploy \
    --template-file .template-output.yml \
    --stack-name $(PROJECT) \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides \
      QiitaAccessToken="$(shell $(call encrypt, ${QIITA_ACCESS_TOKEN}))" \
      QiitaTeamName="$(shell $(call encrypt, ${QIITA_TEAM_NAME}))" \
      QiitaTeamTemplateId="$(shell $(call encrypt, ${QIITA_TEAM_TEMPLATE_ID}))" \
      KmsKeyId="${KMS_KEY_ID}" \
      ScheduleExpression="${SCHEDULE_EXPRESSION}"
.PHONY: deploy
```

復号化は function の中でやりました。

```golang
func decrypt(str string) (string, error) {
	data, err := base64.StdEncoding.DecodeString(str)
	if err != nil {
		return "", err
	}

	svc := kms.New(session.New())
	input := &kms.DecryptInput{
		CiphertextBlob: data,
	}

	resp, err := svc.Decrypt(input)
	if err != nil {
		return "", err
	}

	return string(resp.Plaintext[:]), nil
}

func HandleRequest() (string, error) {
	token, err := decrypt(os.Getenv("QIITA_ACCESS_TOKEN"))
	if err != nil {
		return "", err
	}
	team, err := decrypt(os.Getenv("QIITA_TEAM_NAME"))
	if err != nil {
		return "", err
	}
	templateID, err := decrypt(os.Getenv("QIITA_TEAM_TEMPLATE_ID"))
	if err != nil {
		return "", err
  }
  ...
}
```

これで安全に環境変数を Lambda に設定することができます。

### AWS SAM Local

AWS Lambda の Golang サポートの発表から少し遅れて、先日 [AWS SAM Local](https://github.com/awslabs/aws-sam-local/) も Golang をサポートしました。

> GoLang 1.x support!
>
> [Release v0.2.6 · awslabs/aws-sam-local](https://github.com/awslabs/aws-sam-local/releases/tag/v0.2.6)

SAM と合わせて SAM Local の利用は今回が初めてでしたが、かなり簡単に実行できました。

標準入力または、`-e` オプションで Event の JSON ファイルを渡してあげれば実行できます。

```
$ sam local invoke -e <Event の JSON ファイル名> <Logical ID>
```

ちなみに今回作った function は Event を特に使わないので空文字を渡して実行できました。

```
$ echo '' | sam local invoke
```

ちなみに、YAML ファイルも `template.yaml` または `template.yml` という名前だったらファイル名を指定する必要もありません。

function も 1 つだったら Logical ID を指定する必要もなかったです。

上記コマンドを実行すると、Docker イメージを pull してコンテナ内で Lambda function を実行してくれました。

それ以外はまだ試していませんが、API Gateway や DynamoDB なども扱えるようですね。

## まとめ

今回初めて AWS Lambda を Golang で書き、SAM を使ってみました。

特に有用な知見はなかったかもしれませんが、これから利用する方々の助けとなれば幸いです。

ちなみに、Serverless Framework も Golang をサポートしたようですね。会社では Serverless Framework を使っているのでこちらも触っていきたいです。

[Serverless Framework v1.26.0リリースノート - Qiita](https://qiita.com/horike37/items/86d1626b3ee1a2e86b9a#aws-go-support)
