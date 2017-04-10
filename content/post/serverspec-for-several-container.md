+++
date = "2016-06-25T23:36:05+09:00"
tags = ["docker", "serverspec"]
title = "serverspecで複数のdocker containerに対してテストしたい"

+++

前回の記事でdocker containerに対してserverspecでテストができるようになりました。

[serverspecでdocker containerに対してテストしたい]({{< relref "serverspec-for-docker.md" >}})

dockerを扱う以上、containerは複数立てるのが普通です。

今回は複数のcontainerを立てた時にそれぞれのcontainerに対してテストする方法について書いていきます。

<!--more-->

## やりたいこと
docker-composeで管理している複数のdocker containerに対してテストしたい

## docker-composeで複数のcontainerを管理する
前回のrubyを動かすcontainerに加えて今回はnginxのcontainerを動かしていきます。

まずは、ruby用のDockerfileと実行するrubyスクリプトを配置します。

```dockerfile
# Dockerfile

FROM ruby:2.3.1-alpine

ADD app.rb .
```

```ruby
# app.rb

puts 'Hello, world!'
```

そして、以下のような`docker-compose.yml`を配置します。

```yaml
# docker-compose.yml

app:
  build: .
  command: [ruby, app.rb]
```

この時点で`$ docker-compose up`すると、`Hello, world`と表示されるはずです。

次に、上記のrubyを実行するcontainerとは全く関係ありませんが、nginx containerを別で追加します。

nginxというディレクトリを切り、nginx用のDockerfileと表示するための適当な`index.html`を作ります。

```dockerfile
# nginx/Dockerfile

FROM nginx:stable-alpine

COPY index.html /usr/share/nginx/html
```

```html
<!-- nginx/index.html -->

<strong>Hello, world!</strong>
```

そうしたら、`docker-compose.yml`にnginx serviceの記述も追加しましょう。
私の環境では80をすでに使っていたため、nginxのportは8080にforwardしておきます。

```yaml
app:
  build: .
  command: [ruby, app.rb]
web:
  build: nginx/
  ports:
    - "8080:80"
```

appとwebのcontainerを立ち上げます。

```sh
$ docker-compose up --build
Building web
Step 1 : FROM nginx:stable-alpine
 ---> c6b7a3ab1800
Step 2 : COPY index.html /usr/share/nginx/html
 ---> Using cache
 ---> 4a0b194d5d82
Successfully built 4a0b194d5d82
Building app
Step 1 : FROM ruby:2.3.1-alpine
 ---> c872d09a2f2e
Step 2 : ADD app.rb .
 ---> Using cache
 ---> 8eb82eb96cf9
Successfully built 8eb82eb96cf9
Starting dockerforblogpost20160625_web_1
Starting dockerforblogpost20160625_app_1
Attaching to dockerforblogpost20160625_app_1, dockerforblogpost20160625_web_1
app_1  | Hello, world!
dockerforblogpost20160625_app_1 exited with code 0
```

これで、app containerが立ち上がり、rubyのスクリプトを実行し、nginx containerも同時に立ち上がりました。

`http://localhost:8080`にアクセスしてnginxが立ち上がっているか確認しておきます。

[![](https://i.gyazo.com/2babcf88a2fa4a4093a337e80370ba81.png)](https://gyazo.com/2babcf88a2fa4a4093a337e80370ba81.png)

## 複数のdocker containerに対してテストする
それでは、本題の複数のdocker containerに対してserverspecでテストを実行できる環境を作りましょう。

まずはGemfileを追加します。
今回は複数のdocker containerに対してserverspecを実行するためにrakeも使います。

```ruby
# Gemfile

# frozen_string_literal: true

source "https://rubygems.org"

gem 'serverspec'
gem 'docker-api'
gem 'rake'
```

specディレクトリは以下のように作成します。
`spec/roles`以下に各container毎のテストを書いていきます。

```sh
$ tree spec/
spec/
├── roles
│   ├── app_spec.rb
│   └── web_spec.rb
└── spec_helper.rb

1 directory, 3 files
```

```ruby
# spec/roles/app_spec.rb

require 'spec_helper'

describe 'app' do
  describe command 'ruby -v' do
    let(:disable_sudo) { true }
    its(:stdout) { should match /ruby 2.3.1/ }
  end
end
```

```ruby
# spec/roles/web_spec.rb

require 'spec_helper'

describe 'web' do
  describe file('/usr/share/nginx/html/index.html') do
    it { should exist }
  end
end
```

また、`spec_helper.rb`は以下のように書きます。

docker_imageに指定するimageは環境変数を指定するようにします。
これで、rakeタスクから動的にserverspecを実行するdocker containerを切り替えることができます。

```ruby
# spec/spec_helper.rb

require 'serverspec'
require 'docker'

set :backend, :docker
set :docker_image, ENV['DOCKER_IMAGE_NAME']
```

さて、最後にRakefileを作成します。
hostsの中にdocker containerを定義することで、それぞれのcontainerに対してserverspecを実行できます。

nameにはdocker-composeで作成されたimage名、short_nameはrake taskで使う名前、roleは`spec/roles`以下に配置するファイル名を指定します。

serverspec実行時のENVにそれぞれのimage名を渡してあげます。

```ruby
# Rakefile

require 'rake'
require 'rspec/core/rake_task'

hosts = [
  {
    name:       'dockersandbox_app',
    short_name: 'app',
    roles:      'app',
  },
  {
    name:       'dockersandbox_web',
    short_name: 'web',
    roles:      'web',
  }
]

class ServerspecTask < RSpec::Core::RakeTask
  attr_accessor :target

  def spec_command
    cmd = super
    "env DOCKER_IMAGE_NAME=#{target} #{cmd}"
  end
end

task default: :spec

desc 'Run serverspec to all hosts'
task spec: hosts.map { |h| "spec:#{h[:short_name]}" }

namespace :spec do
  hosts.each do |host|
    desc "Run serverspec to #{host[:name]}"
    ServerspecTask.new(host[:short_name].to_sym) do |t|
      t.target = host[:name]
      t.pattern = "spec/roles/#{host[:roles]}_spec.rb"
    end
  end
end
```

これで、`spec/roles`以下に置かれたファイルごとにserverspecが実行されます。

```sh
$ bundle exec rake spec
app
  Command "ruby -v"
    stdout
      should match /ruby 2.3.1/

Finished in 3.29 seconds (files took 0.83075 seconds to load)
1 example, 0 failures

web
  File "/usr/share/nginx/html/index.html"
    should exist

Finished in 3.18 seconds (files took 0.64689 seconds to load)
1 example, 0 failures
```
