#!/bin/sh
set -eo pipefail

# Install Wordpress
if ! $(wp core is-installed); then
    wp core install --allow-root --path=/var/www/html --url="${WORDPRESS_WEBSITE_URL}"  --title="Default Website" --admin_user="${WORDPRESS_ADMIN_USER}" --admin_password="${WORDPRESS_ADMIN_PASSWORD}" --admin_email="${WORDPRESS_ADMIN_EMAIL}"
fi

exec "$@"