FROM nginx:alpine
LABEL maintainer "tsub <tsubasatakayama511@gmail.com>"

COPY --from=tsub/blog:hugo /app/public /usr/share/nginx/html
COPY default.nginx /etc/nginx/conf.d/default.conf
