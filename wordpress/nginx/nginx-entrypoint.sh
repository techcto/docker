#!/bin/sh
set -eo pipefail

# Update App URL
sed -i -e "s/{{APP_URL}}/${APP_URL}/g" /etc/nginx/conf.d/default.conf

if [ -z ${APP_ENV+x} ] && [ "$APP_ENV" != "dev" ]; then
    #Update Hosts file to resolve local solodev
    echo "#PHP-FPM" >> /etc/hosts
    echo "127.0.0.1 ${APP_URL}" >> /etc/hosts
fi

COMMAND=${COMMAND:="nginx"}
echo ${COMMAND}

${COMMAND}