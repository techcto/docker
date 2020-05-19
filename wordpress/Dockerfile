FROM 'wordpress:5.4-fpm-alpine'

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && php wp-cli.phar --info \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp \
    && wp --info

#Entrypoint
COPY ./docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod a+rx /docker-entrypoint.sh

ENTRYPOINT ["sh", "/docker-entrypoint.sh"]