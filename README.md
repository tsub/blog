# blog [![CircleCI](https://circleci.com/gh/tsub/blog.svg?style=svg&circle-token=a0245862ab624bb1211d85197913a3984f7bbdd9)](https://circleci.com/gh/tsub/blog)

## Getting started

```
$ git clone git@github.com:tsub/blog.git
$ cd blog
$ bin/setup
```

## How to add new post

```
$ docker-compose run --rm hugo new post/post-title.md
```

## How to Deploy

1. [Create a new release](https://github.com/tsub/blog/releases/new)
2. Push [tsub/blog](https://hub.docker.com/r/tsub/blog/) image to DockerHub on CircleCI

### Manual deployment

```
$ bin/build
$ docker login
$ bin/deploy <tag>
```
