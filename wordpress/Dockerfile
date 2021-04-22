FROM techcto/alpine-php-fpm-7.2:1.0

#Patch
RUN apk add --upgrade libcurl mysql mysql-client

RUN mkdir -p /usr/local/bin
COPY ./wait-for-it.sh /usr/local/bin/wait-for-it.sh
RUN chmod a+rx /usr/local/bin/wait-for-it.sh

#Swap
RUN /bin/dd if=/dev/zero of=/mnt/swapfile bs=1M count=2048 \
    && chown root:root /mnt/swapfile \
    && chmod 600 /mnt/swapfile \
    && /sbin/mkswap /mnt/swapfile \
    && /sbin/swapon -a

#Set Environment
ENV APP_DIR=/var/www/html \
    COMPOSER_CACHE_DIR=/var/cache/composer \
    COMPOSER_ALLOW_SUPERUSER=1 \
    RESOLVE_LOGGING=false

ENV PATH=/usr/local/bin:${APP_DIR}/bin:${APP_DIR}/vendor/bin:${PATH}

WORKDIR ${APP_DIR}

RUN set -ex

ARG APP_ENV=dev
ENV APP_ENV ${APP_ENV}
    
#Install App
COPY ./init.sh /root/init.sh
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && php wp-cli.phar --info \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp \
    && wp --info

#Configure Tmp & Session
RUN mkdir -p /var/lib/php/tmp \
    && mkdir -p /var/www/html/tmp \
    && mkdir -p /var/lib/php/session \
    && mkdir -p ${COMPOSER_CACHE_DIR} \
    && chown -Rf www-data:www-data /var/lib/php/tmp /var/www/html/tmp /var/lib/php/session ${COMPOSER_CACHE_DIR} \
    && chmod -Rf 770 /var/lib/php/tmp /var/www/html/tmp /var/lib/php/session ${COMPOSER_CACHE_DIR}

#Install Plugins
COPY ./plugins/sso.zip /var/www/html/tmp/sso.zip

COPY ./php.ini /usr/local/etc/php/php.ini
COPY ./php-fpm.conf /usr/local/etc/php-fpm.conf

#Entrypoint
COPY ./docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod a+rx /docker-entrypoint.sh

ENTRYPOINT ["sh", "/docker-entrypoint.sh"]