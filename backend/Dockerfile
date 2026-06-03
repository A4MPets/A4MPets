FROM composer:2 AS vendor
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-interaction --prefer-dist --no-progress --no-scripts

FROM php:8.4-cli

RUN apt-get update \
    && apt-get install -y --no-install-recommends git unzip curl libsqlite3-dev pkg-config \
    && docker-php-ext-install pdo_sqlite \
    && rm -rf /var/lib/apt/lists/*

RUN printf '%s\n' \
    'post_max_size = 0' \
    'upload_max_filesize = 0' \
    > /usr/local/etc/php/conf.d/a4mpets-media.ini

WORKDIR /var/www/html

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY --from=vendor /app/vendor ./vendor
COPY . .

RUN chmod +x /var/www/html/docker/entrypoint.sh

EXPOSE 8000

ENTRYPOINT ["/var/www/html/docker/entrypoint.sh"]
