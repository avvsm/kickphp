FROM php:fpm

ADD https://getcomposer.org/installer /usr/local/bin/composer-installer

RUN apt-get update && apt-get install --yes \
    cron \
    gettext \
    nginx \
&& pecl install \
    redis \
&& docker-php-ext-install \
    pdo_mysql \
&& docker-php-ext-enable \
    redis \
&& php /usr/local/bin/composer-installer --install-dir=/usr/local/bin --filename=composer \
&& service nginx stop

EXPOSE 80
# Port 9000 is exposed by php:~fpm image

CMD ["exit", "0"]
