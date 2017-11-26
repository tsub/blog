FROM steveltn/https-portal:1
LABEL maintainer "tsub <tsubasatakayama511@gmail.com>"

ENV BLOG_DOMAIN="blog.tsub.me"

COPY --from=tsub/blog:hugo /app/public /var/www/vhosts/${BLOG_DOMAIN}
