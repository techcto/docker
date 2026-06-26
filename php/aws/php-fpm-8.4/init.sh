#!/bin/bash
set -euo pipefail

#Install Package Repos (REMI, EPEL)
dnf -y remove php* httpd*

#Install dnf-plugins-core first
dnf -y install dnf-plugins-core

#Install critical tools immediately (including tar for helm)
dnf -y install wget curl-minimal unzip tar gzip

#Install remaining devtools
dnf -y install gcc-c++ gcc pcre-devel make zip cmake git dnf-utils sudo sendmail jq sshpass

#Update all libs
dnf update -y

#AWS
curl -qL -o packer.zip https://releases.hashicorp.com/packer/0.12.3/packer_0.12.3_linux_amd64.zip && unzip packer.zip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

#Install Apache 2.4
dnf install -y httpd
sed -i 's/LoadModule mpm_prefork_module/#LoadModule mpm_prefork_module/g' /etc/httpd/conf.modules.d/00-mpm.conf
sed -i 's/#LoadModule mpm_event_module/LoadModule mpm_event_module/g' /etc/httpd/conf.modules.d/00-mpm.conf

# Helper function to handle systemd in Docker
systemctl_wrapper() {
    if [ ! -d /run/systemd/system ]; then
        systemctl enable "$1" || true
    else
        systemctl enable "$1"
        systemctl start "$1"
    fi
}

systemctl_wrapper httpd

#Install SSL
dnf -y install openssl openssl-devel mod_ssl
sed -i 's/SSLProtocol all -SSLv2$/SSLProtocol all -SSLv2 -SSLv3/g' /etc/httpd/conf.d/ssl.conf

#Helm
export PATH=/usr/bin:$PATH
command -v tar &>/dev/null || dnf install -y tar
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

#Install PHP-FPM 8.4 (Amazon Linux 2023 — explicit versioned packages)
dnf install -y tidy \
    php8.4 php8.4-fpm php8.4-common php8.4-sodium \
    php8.4-devel php8.4-mysqlnd php8.4-pdo \
    php8.4-gd php8.4-mbstring php-pear php8.4-soap php8.4-tidy \
    php8.4-pecl-apcu php8.4-pecl-redis6 php8.4-opcache

# Make 'php' resolve to 8.4 when the distro exposes a versioned binary.
if [ -x /usr/bin/php8.4 ]; then
    update-alternatives --set php /usr/bin/php8.4 2>/dev/null || ln -sf /usr/bin/php8.4 /usr/bin/php
fi

if ! command -v php &> /dev/null; then
    echo "ERROR: PHP 8.4 installation failed." && exit 1
fi

# Fail fast if wrong PHP version installed
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
if [ "$PHP_VERSION" != "8.4" ]; then
    echo "ERROR: PHP 8.4 required, got $PHP_VERSION" && exit 1
fi

# Install MongoDB Server and PHP extension
cat > /etc/yum.repos.d/mongodb-org-7.0.repo <<'EOF'
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2023/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://pgp.mongodb.com/server-7.0.asc
EOF

dnf install -y mongodb-org mongodb-mongosh
systemctl_wrapper mongod

# Install MongoDB PHP driver via PECL
dnf install -y php-pear php8.4-devel openssl-devel
pecl install mongodb
echo "extension=mongodb.so" > /etc/php.d/40-mongodb.ini

#Configure PHP-FPM conf for Apache (php84-php.conf)
rm -Rf /etc/httpd/conf.d/php.conf
mkdir -p /run/php-fpm
echo '<Files ".user.ini">' >> /etc/httpd/conf.d/php84-php.conf
echo 'Require all denied' >> /etc/httpd/conf.d/php84-php.conf
echo '</Files>' >> /etc/httpd/conf.d/php84-php.conf
echo "AddHandler .stml .php" >> /etc/httpd/conf.d/php84-php.conf
echo "AddType text/html .stml .php" >> /etc/httpd/conf.d/php84-php.conf
echo "DirectoryIndex index.stml index.php" >> /etc/httpd/conf.d/php84-php.conf
echo 'SetEnvIfNoCase ^Authorization$ "(.+)" HTTP_AUTHORIZATION=$1' >> /etc/httpd/conf.d/php84-php.conf
echo "<FilesMatch \.(php|phar|stml)$>" >> /etc/httpd/conf.d/php84-php.conf
echo ' SetHandler "proxy:unix:/run/php-fpm/www.sock|fcgi://localhost"' >> /etc/httpd/conf.d/php84-php.conf
echo "</FilesMatch>" >> /etc/httpd/conf.d/php84-php.conf

# Ensure PHP-FPM config directory exists
PHP_FPM_D=$(find /etc -maxdepth 1 -name "php*fpm.d" -type d 2>/dev/null | head -1)
[ -z "$PHP_FPM_D" ] && PHP_FPM_D="/etc/php8.4-fpm.d" && mkdir -p "$PHP_FPM_D"
if [ ! -f "${PHP_FPM_D}/www.conf" ]; then
    cp "${PHP_FPM_D}/www.conf.default" "${PHP_FPM_D}/www.conf" 2>/dev/null || touch "${PHP_FPM_D}/www.conf"
fi

echo "security.limit_extensions = .php .stml" >> "${PHP_FPM_D}/www.conf"
echo "listen = /run/php-fpm/www.sock" >> "${PHP_FPM_D}/www.conf"
echo "listen.owner = apache" >> "${PHP_FPM_D}/www.conf"
echo "listen.mode = 0660" >> "${PHP_FPM_D}/www.conf"

#Install Node
mkdir -p /var/www/.npm
mkdir -p /var/www/.npm-global
echo 'export NODE_PATH=/var/www/.npm-global/lib/node_modules' >> /var/www/.npmrc
echo 'export PATH=$PATH:/var/www/.npm-global/bin' >> /var/www/.npmrc
export PATH=/var/www/.npm-global/bin:$PATH

# Install Node.js (Amazon Linux 2023 native)
dnf install -y nodejs npm

npm config set prefix '/var/www/.npm-global'
npm install -g autoprefixer clean-css-cli nodemon npm-run-all postcss-cli postcss-discard-empty shx uglify-js
npm install -g -f --unsafe-perm node-sass
chmod 2770 /var/www/.npmrc
chown apache.apache /var/www/.npmrc
chmod -Rf 2770 /var/www/.npm
chown -Rf apache.apache /var/www/.npm
chmod -Rf 2770 /var/www/.npm-global
chown -Rf apache.apache /var/www/.npm-global

#Install Composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/bin/composer
chmod +x /usr/bin/composer

# Ensure wget and tar are available for IonCube
dnf install -y wget tar

#Install IonCube
wget http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
tar -xzf ioncube_loaders_lin_x86-64.tar.gz
cd ioncube/
PHP_EXT_DIR=$(php -r "echo ini_get('extension_dir');")
cp ioncube_loader_lin_${PHP_VERSION}.so ${PHP_EXT_DIR}/ || cp ioncube_loader_lin_8.*.so ${PHP_EXT_DIR}/ioncube_loader.so

#Configure php.ini
PHP_INI=$(php --ini | grep "Loaded Configuration" | awk '{print $NF}')
[ -z "$PHP_INI" ] && PHP_INI="/etc/php.ini"
echo "short_open_tag = On" >> ${PHP_INI}
echo "expose_php = Off" >>${PHP_INI}
echo "max_execution_time = 90" >>${PHP_INI}
echo "max_input_time = 90" >>${PHP_INI}
echo "error_reporting = E_ALL & ~E_DEPRECATED & ~E_NOTICE & ~E_STRICT & ~E_WARNING" >>${PHP_INI}
echo "post_max_size = 60M" >>${PHP_INI}
echo "upload_max_filesize = 60M" >>${PHP_INI}
#echo "allow_url_fopen = Off" >>${PHP_INI}
echo "date.timezone = UTC" >>${PHP_INI}
echo "realpath_cache_size = 1M" >>${PHP_INI}
echo "session.cookie_httponly = 1" >>${PHP_INI}
echo "[apcu]" >>${PHP_INI}
echo "apc.enabled=1" >>${PHP_INI}
echo "apc.shm_size=32M" >>${PHP_INI}
echo "apc.ttl=7200" >>${PHP_INI}
echo "apc.enable_cli=0" >>${PHP_INI}
echo "apc.serializer=php" >>${PHP_INI}
echo "apc.stat=0" >>${PHP_INI}
echo "[custom]" >>${PHP_INI}
echo "realpath_cache_ttl = 7200" >>${PHP_INI}
echo "realpath_cache_size = 4096k" >>${PHP_INI}
echo "opcache.enable=1" >>${PHP_INI}
echo "opcache.memory_consumption=128" >>${PHP_INI}
echo "opcache.max_accelerated_files=4000" >>${PHP_INI}
echo "opcache_revalidate_freq = 240" >>${PHP_INI}
echo "zend_extension=${PHP_EXT_DIR}/ioncube_loader.so" >>${PHP_INI}

#Activate
systemctl_wrapper php8.4-fpm
systemctl_wrapper httpd || true

#Cleanup
rm -Rf /root/.ssh
rm -Rf /home/ec2-user/.ssh
