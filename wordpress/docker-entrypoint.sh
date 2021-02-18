#!/bin/sh
set -eo pipefail

echo "Booting up Wordpress"

cd "$APP_DIR"

export DOCKER_BRIDGE_IP=$(/sbin/ip route|awk '/default/ { print $3 }')

# Skip entrypoint for following commands
case "$1" in
   sh|php|composer) exec "$@" && exit 0;;
esac

if [ ! -z "$SKIP_ENTRYPOINT" ]; then
    exec "$@" && exit 0
fi

# Set variable from env file if variable not defined
loadEnvFile() {
    OLD_IFS="$IFS"
    IFS='='
    while read env_name env_value
    do
        if [ -z "$env_name" ]; then continue; fi

        IFS=
        eval `echo export ${env_name}=\$\{${env_name}\:=${env_value}\}`
        IFS='='
    done < $1
    IFS="$OLD_IFS"
}

if [ -f "$APP_DIR/.env" ]; then
    loadEnvFile "$APP_DIR/.env"
fi

case "$APP_ENV" in
   prod|dev|test) ;;
   *) >&2 echo env "APP_ENV" must be in \"prod, dev, test\" && exit 1;;
esac

COMMAND="$@"

if [ "$APP_ENV" == "dev" ]; then
    XDEBUG=${XDEBUG:=true}
    OPCACHE=${OPCACHE:=false}
    APCU=${APCU:=false}

elif [ "$APP_ENV" == "test" ]; then
    if [ -f "$APP_DIR/.env.dist" ]; then
        loadEnvFile "$APP_DIR/.env.dist"
    fi
fi

COMMAND=${COMMAND:="php-fpm -F"}
OPCACHE=${OPCACHE:=true}
APCU=${APCU:=true}

echo "Enabling extensions"

enableExt() {
    extension=$1
    docker-php-ext-enable ${extension}

    if [ "$APP_DEBUG" == 1 ]; then
        echo -e " > $extension enabled"
    fi
}

if [ "$APCU" == "true" ]; then
    enableExt apcu
fi

if [ ! -z "$COMPOSER_EXEC" ]; then
    ${COMPOSER_EXEC}
fi

rm -rf $APP_DIR/var/cache/*

# if [ "$XDEBUG" == "true" ]; then
#     docker-php-ext-install xdebug
#     enableExt xdebug
# fi

chmod -Rf 2770 /root/init.sh && chown -Rf www-data:www-data /root/init.sh ./* && chmod 755 ./wp-content/uploads/* && ls -al
/root/init.sh &>/dev/stdout
chmod 777 /dev/urandom

${COMMAND}