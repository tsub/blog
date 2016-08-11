+++
date = "2016-06-25T22:25:08+09:00"
tags = ["docker", "serverspec"]
title = "serverspecでdocker containerに対してテストしたい"

+++

仕事でこれからdockerを使い始めるので、dockerを触りつつメモがてら記事に残していきます。

<!--more-->

## やりたいこと
docker containerに対してserverspecでテストしたい

## docker containerに対してテストする
serverspecはバックエンドとして通常のsshやexec以外にもdockerをサポートしています。

他にもdockerfileというバックエンドも使えるようですが、こちらは軽くソースを見たところDockerfileのADDやRUNなどの記述に対してのテストのように見えますので、serverspecの書き方も少し変わってくるかもしれません。
ググッてもあまりdockerfileというバックエンドを使っている記事は見つからなかったのであまり使われていないようです。

今回は既存のserverspecの資産をなるべくそのまま活かしていきたいのでdockerバックエンドを使います。

[mizzy/specinfra/backend/docker.rb](https://github.com/mizzy/specinfra/blob/master/lib/specinfra/backend/docker.rb)

ServerspecのバックエンドとしてDockerを使うにはこちらのdocker-apiというgemをインストールする必要があります。

[swipely/docker-api](https://github.com/swipely/docker-api)

このdocker-apiはDockerのRemote APIを叩くためのgemで、このgemを使ってserverspecがテストを実行してくれます。

```ruby
# Gemfile

# frozen_string_literal: true
source "https://rubygems.org"

gem 'serverspec'
gem 'docker-api'
```

spec_helperに`set :backend, :docker`と`set :docker_image, 'image_name'`を指定すると、
serverspecがテストを実行するときに自動でdocker imageに対してdocker execコマンドを実行し、テストしてくれるようになります。

```ruby
# spec/spec_helper.rb

require 'serverspec'
require 'docker'

set :backend, :docker
set :docker_image, 'app'
```

さて、今回は以下のDockerfileを使います。

```dockerfile
# Dockerfile

FROM ruby:2.3.1-alpine

ADD app.rb .
```

実行したい`app.rb`を適当に作っておきます。

```ruby
# app.rb

puts 'Hello, world!'
```

テストファイルも作っておきます。

```ruby
# spec/ruby_spec.rb

describe command 'ruby -v' do
  let(:disable_sudo) { true }
  its(:stdout) { should match /ruby 2.3.1/ }
end
```

spec_helperでdocker_imageと指定しているように、serverspecの実行にはdocker imageを作っておく必要があるため、事前にdocker buildしておきます。

```sh
$ docker build -t app .
```

さて、ここまでできたらserverspecを実行してみましょう。

```sh
$ bundle exec rspec
Command "ruby -v"
  stdout
    should match /ruby 2.3.1/

Finished in 2.37 seconds (files took 0.62684 seconds to load)
1 example, 0 failures
```

無事にテストできました。

## 注意
Dockerfileで最後にCMDとか書いておくと、なぜかserverspecでcontainerを見つけられません。

```dockerfile
# Dockerfile

FROM ruby:2.3.1-alpine

ADD app.rb .

CMD ["ruby", "app.rb"]
```

```sh
$ bundle exec rspec
Command "ruby -v"
  stdout
    example at ./spec/shared/ruby_spec.rb:4 (FAILED - 1)

Failures:

  1) worker behaves like ruby Command "ruby -v" stdout
     Failure/Error: its(:stdout) { should match /ruby 2.3.1/ }
     Docker::Error::ServerError:
       Container 695ddb15d393210654720468c54924658569edbe4c00cf6832961443440e6969 is not running

     Shared Example Group: "ruby" called from ./spec/ruby_spec.rb:3
     # ./vendor/bundle/gems/docker-api-1.29.0/lib/docker/connection.rb:50:in `rescue in request'
     # ./vendor/bundle/gems/docker-api-1.29.0/lib/docker/connection.rb:38:in `request'
     # ./vendor/bundle/gems/docker-api-1.29.0/lib/docker/connection.rb:65:in `block (2 levels) in <class:Connection>'
     # ./vendor/bundle/gems/docker-api-1.29.0/lib/docker/exec.rb:22:in `create'
     # ./vendor/bundle/gems/docker-api-1.29.0/lib/docker/container.rb:64:in `exec'
     # ./vendor/bundle/gems/specinfra-2.59.3/lib/specinfra/backend/docker.rb:94:in `docker_run!'
     # ./vendor/bundle/gems/specinfra-2.59.3/lib/specinfra/backend/docker.rb:31:in `run_command'
     # ./vendor/bundle/gems/specinfra-2.59.3/lib/specinfra/helper/detect_os.rb:13:in `run_command'
     # ./vendor/bundle/gems/specinfra-2.59.3/lib/specinfra/helper/detect_os/redhat.rb:11:in `detect'
     # ./vendor/bundle/gems/specinfra-2.59.3/lib/specinfra/helper/detect_os.rb:5:in `detect'
     # ./vendor/bundle/gems/specinfra-2.59.3/lib/specinfra/helper/os.rb:24:in `block in detect_os'
     # ./vendor/bundle/gems/specinfra-2.59.3/lib/specinfra/helper/os.rb:23:in `each'
     # ./vendor/bundle/gems/specinfra-2.59.3/lib/specinfra/helper/os.rb:23:in `detect_os'
     # ./vendor/bundle/gems/specinfra-2.59.3/lib/specinfra/helper/os.rb:9:in `os'
     # ./vendor/bundle/gems/specinfra-2.59.3/lib/specinfra/runner.rb:7:in `method_missing'
     # ./vendor/bundle/gems/serverspec-2.36.0/lib/serverspec/type/command.rb:17:in `command_result'
     # ./vendor/bundle/gems/serverspec-2.36.0/lib/serverspec/type/command.rb:4:in `stdout'
     # ./spec/shared/ruby_spec.rb:4:in `block (3 levels) in <top (required)>'
     # ------------------
     # --- Caused by: ---
     # Excon::Errors::InternalServerError:
     #   Expected([200, 201, 202, 203, 204, 304]) <=> Actual(500 InternalServerError)
     #   ./vendor/bundle/gems/excon-0.49.0/lib/excon/middlewares/expects.rb:6:in `response_call'

Finished in 0.9004 seconds (files took 1.01 seconds to load)
1 example, 1 failure

Failed examples:

rspec ./spec/ruby_spec.rb:3 # Command "ruby -v" stdout
```

CMDではなく、docker runの引数に渡すようにすると良いと思います。

```dockerfile
# Dockerfile

FROM ruby:2.3.1-alpine

ADD app.rb .
```

```sh
$ docker run --rm app ruby app.rb
Hello, world!
```
