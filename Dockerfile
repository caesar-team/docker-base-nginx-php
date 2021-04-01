FROM php:7.4-fpm-alpine AS base
LABEL Maintainer="Aleksandr Beshkenade <ab@caesar.team>" \
      Description="Lightweight container with Nginx 1.18 & PHP-FPM 7.4 based on Alpine Linux."

RUN apk --update add \
    curl \
    nginx \
    supervisor \
    git \
    zip \
    gpgme

RUN apk add --no-cache --no-progress --virtual BUILD_DEPS ${PHPIZE_DEPS}
RUN apk add --no-cache --no-progress --virtual BUILD_DEPS_PHP \
    libzip-dev \
    icu-dev \
    icu-dev \
    gpgme-dev \
    libzip-dev \
    postgresql-dev \
    rabbitmq-c \
    rabbitmq-c-dev

RUN docker-php-ext-install \
    intl \
    bcmath\
    opcache \
    zip \
    sockets \
    pdo \
    pdo_pgsql \
    zip

RUN pecl install gnupg redis amqp \
    && docker-php-ext-enable redis amqp

RUN apk del --no-progress BUILD_DEPS BUILD_DEPS_PHP ${PHPIZE_DEPS}
# Configure composer:2
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
# Configure nginx
COPY config/nginx/nginx.conf /etc/nginx/nginx.conf
# Configure PHP-FPM
COPY config/php/fpm-pool.conf /usr/local/etc/php-fpm.d/www.conf
COPY config/php/php.ini /usr/local/etc/php/conf.d/custom.ini
# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /var/www/html && \
  chown -R nobody.nobody /run && \
  chown -R nobody.nobody /var/lib/nginx && \
  chown -R nobody.nobody /var/log/nginx && \
  mkdir -p /var/www/html /var/www/html/public/static && \
  mkdir -p /var/www/html/var/cache /var/www/html/var/logs && \
  mkdir -p /var/www/html/var/sessions /var/www/html/var/jwt && \
  chown -R nobody.nobody /var/www/html

## ---- Release ----
FROM base AS release
EXPOSE 8080
USER nobody
ENV APP_ENV=prod
COPY --chown=nobody:nobody ./bin/entrypoint.sh /var/www/html/bin/entrypoint.sh
COPY --chown=nobody:nobody ./public/index.php /var/www/html/public/index.php
# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping