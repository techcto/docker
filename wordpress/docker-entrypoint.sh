#!/bin/sh
set -eo pipefail

# Install Wordpress
wp core install --url="${WORDPRESS_WEBSITE_URL}"  --title="Default Website" --admin_user="${WORDPRESS_ADMIN_USER}" --admin_password="${WORDPRESS_ADMIN_PASSWORD}" --admin_email="${WORDPRESS_ADMIN_EMAIL}"

exec "$@"