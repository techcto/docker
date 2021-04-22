#!/bin/sh
set -eo pipefail

#Mail
echo "Start Postfix"
HOST=`hostname -f`
echo "myhostname = $HOST" >> /etc/postfix/main.cf && \
echo "mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128" >> /etc/postfix/main.cf && \
echo "inet_interfaces = all" >> /etc/postfix/main.cf
chmod 2770 /var/log
# rsyslogd
postfix start

# Wait for db
/usr/local/bin/wait-for-it.sh ${WORDPRESS_DB_HOST}:3306 -t 200
echo "DB Ready!"

#Install App
install() {
    #Set config from environment variables
    CONFIG="${APP_DIR}/.env"
    if [ ! -f $CONFIG ] ; then
        if [ ! -z "$CLIENT_ID" ] ; then
            echo "SSO_CLIENT_ID=${CLIENT_ID}" >> $CONFIG
            echo "SSO_CLIENT_SECRET=${CLIENT_SECRET}" >> $CONFIG
            echo "SSO_REDIRECT_URI=http://localhost/login/id" >> $CONFIG
            echo "SSO_URL_AUTHORIZE=https://id.solodev.com/oauth2/authorize" >> $CONFIG
            echo "SSO_URL_ACCESS_TOKEN=https://id.solodev.com/oauth2/access_token" >> $CONFIG
            echo "SSO_URL_KEY_SET=https://portal.solodev.com/.well-known/jwks.json" >> $CONFIG
        fi
    fi

    echo "Install Complete"
}

#Update App
update() {
    echo "Update Complete"
}

echo $(ls)
echo "Start App Init"
echo $PWD
echo "Finish App Init"
echo $(wp core is-installed --path='/var/www/html' --allow-root)

# Install Wordpress
echo "Check Wordpress"
if ! $(wp core is-installed --path='/var/www/html' --allow-root); then
    # rm -f wp-config-sample.php
    install
    rm -Rf ./wp-content/plugins/*
    echo "Install Wordpress"
    wp core download --allow-root
    wp core config --allow-root --dbhost=${WORDPRESS_DB_HOST} --dbname=${WORDPRESS_DB_NAME} --dbuser=${WORDPRESS_DB_USER} --dbpass=${WORDPRESS_DB_PASSWORD}
    wp core install --allow-root \
        --url=${WORDPRESS_WEBSITE_URL} \
        --title='Default website' \
        --admin_user=${WORDPRESS_ADMIN_USER} \
        --admin_password=${WORDPRESS_ADMIN_PASSWORD} \
        --admin_email=${WORDPRESS_ADMIN_EMAIL}
    wp config --allow-root set FS_METHOD direct
    wp plugin install --allow-root ./tmp/sso.zip --activate
    wp rewrite structure '/%postname%/' --allow-root
else
    wp option update --allow-root siteurl ${WORDPRESS_WEBSITE_URL}
    update
fi

chmod 755 ./* && chown -Rf www-data:www-data ./*

echo "Finish Wordpress Init"