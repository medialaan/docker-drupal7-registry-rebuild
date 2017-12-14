FROM php:7.1-alpine

RUN apk update \
 && apk add --virtual .phpize-deps $PHPIZE_DEPS \
 && NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) \
 && apk add libmemcached zlib cyrus-sasl \
 && pecl install igbinary-2.0.5 \
 && apk add --virtual .php-ext-memcached-deps libmemcached-dev zlib-dev cyrus-sasl-dev \
 && pecl bundle memcached-3.0.3 \
 && rm memcached-3.0.3.tgz \
 && cd memcached \
 && phpize \
 && ./configure --enable-memcached-igbinary \
 && make -j${NPROC} \
 && make install \
 && cd .. \
 && rm -r memcached \
 && docker-php-ext-install -j${NPROC} pdo pdo_mysql \
 && docker-php-ext-enable igbinary memcached \
 && apk del .phpize-deps .php-ext-memcached-deps \
 && rm -rf /var/cache/apk/*

RUN curl -fSL "https://ftp.drupal.org/files/projects/registry_rebuild-7.x-2.5.tar.gz" -o registry_rebuild.tar.gz \
 && tar -xz -f registry_rebuild.tar.gz -C / \
 && rm registry_rebuild.tar.gz

ENTRYPOINT ["php", "registry_rebuild/registry_rebuild.php"]

CMD ["--root=/drupal_root"]
