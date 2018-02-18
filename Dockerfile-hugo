FROM frolvlad/alpine-glibc:alpine-3.6
LABEL maintainer "tsub <tsubasatakayama511@gmail.com>"

ENV HUGO_VERSION="0.36.1"

RUN apk add --update --no-cache --virtual build-dependencies \
        git \
        curl && \
    curl -fSL -o hugo.tar.gz "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz" && \
    tar -zxvf hugo.tar.gz -C /usr/local/bin && \
    rm hugo.tar.gz && \
    apk del --purge build-dependencies

COPY . /app
WORKDIR /app
RUN hugo

ENTRYPOINT ["hugo"]
