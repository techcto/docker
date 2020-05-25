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

# Install Wordpress
echo "Check Wordpress"
if ! $(wp core is-installed --allow-root); then
    # rm -f wp-config-sample.php
    echo "Install Wordpress"
    wp core download --allow-root
    wp core config --allow-root --dbhost=${WORDPRESS_DB_HOST} --dbname=${WORDPRESS_DB_NAME} --dbuser=${WORDPRESS_DB_USER} --dbpass=${WORDPRESS_DB_PASSWORD}
    wp core install --allow-root \
        --url=${WORDPRESS_WEBSITE_URL} \
        --title='Default website' \
        --admin_user=${WORDPRESS_ADMIN_USER} \
        --admin_password=${WORDPRESS_ADMIN_PASSWORD} \
        --admin_email=${WORDPRESS_ADMIN_EMAIL}
else
    wp option update siteurl ${WORDPRESS_WEBSITE_URL}
fi

echo "Finish Wordpress Init"