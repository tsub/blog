FROM nginx:alpine
LABEL maintainer "tsubasatakayama511@gmail.com"

COPY public /usr/share/nginx/html
COPY default.nginx /etc/nginx/conf.d/default.conf
