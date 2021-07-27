#Install Package Repos (REMI, EPEL)
yum -y remove php* httpd*

#Install Required Devtools
yum -y install gcc-c++ gcc pcre-devel make zip unzip wget curl cmake git yum-utils sudo sendmail
yum -y install scl-utils

#Install Required Repos
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
wget http://rpms.remirepo.net/enterprise/remi-release-7.rpm
rpm -Uvh epel-release-latest-7.noarch.rpm
rpm -Uvh remi-release-7.rpm
yum-config-manager --enable remi-php74
yum --enablerepo=epel -y install libwebp

#Update all libs
yum update -y

#Install Apache 2.4
yum --enablerepo=epel,remi install -y httpd
sed -i 's/LoadModule mpm_prefork_module/#LoadModule mpm_prefork_module/g' /etc/httpd/conf.modules.d/00-mpm.conf
sed -i 's/#LoadModule mpm_event_module/LoadModule mpm_event_module/g' /etc/httpd/conf.modules.d/00-mpm.conf
service httpd start
chkconfig httpd on

#Install SSL
yum -y install openssl-devel mod_ssl
sed -i 's/SSLProtocol all -SSLv2$/SSLProtocol all -SSLv2 -SSLv3/g' /etc/httpd/conf.d/ssl.conf

#Install PHP-FPM 7.4
yum install -y tidy php74-php-fpm php74-php-common \
php74-php-devel php74-php-mysqli php74-php-mysqlnd php74-php-pdo_mysql \
php74-php-gd php74-php-mbstring php74-php-pear php74-php-soap php74-php-tidy \
php74-php-pecl-mongodb php74-php-pecl-apcu php74-php-pecl-oauth php74-php-pecl-zip php74-php-pecl-redis
scl enable php74 'php -v'
ln -s /usr/bin/php74 /usr/bin/php

#Configure PHP-FPM conf for Apache (php74-php.conf)
rm -Rf /etc/httpd/conf.d/php.conf
mkdir -p /run/php-fpm
echo '<Files ".user.ini">' >> /etc/httpd/conf.d/php74-php.conf
echo 'Require all denied' >> /etc/httpd/conf.d/php74-php.conf
echo '</Files>' >> /etc/httpd/conf.d/php74-php.conf
echo "AddHandler .stml .php" >> /etc/httpd/conf.d/php74-php.conf
echo "AddType text/html .stml .php" >> /etc/httpd/conf.d/php74-php.conf
echo "DirectoryIndex index.stml index.php" >> /etc/httpd/conf.d/php74-php.conf
echo 'SetEnvIfNoCase ^Authorization$ "(.+)" HTTP_AUTHORIZATION=$1' >> /etc/httpd/conf.d/php74-php.conf
echo "<FilesMatch \.(php|phar|stml)$>" >> /etc/httpd/conf.d/php74-php.conf
echo ' SetHandler "proxy:unix:/run/php-fpm/www.sock|fcgi://localhost"' >> /etc/httpd/conf.d/php74-php.conf
echo "</FilesMatch>" >> /etc/httpd/conf.d/php74-php.conf
echo "security.limit_extensions = .php .stml" >> /etc/opt/remi/php74/php-fpm.d/www.conf
echo "listen = /run/php-fpm/www.sock" >> /etc/opt/remi/php74/php-fpm.d/www.conf
echo "listen.owner = apache" >> /etc/opt/remi/php74/php-fpm.d/www.conf
echo "listen.mode = 0660" >> /etc/opt/remi/php74/php-fpm.d/www.conf

#Install Node
mkdir -p /var/www/.npm
echo 'export NODE_PATH=/var/www/.npm-global/lib/node_modules' >> /var/www/.npmrc
echo 'export PATH=$PATH:/var/www/.npm-global/bin' >> /var/www/.npmrc
export PATH=/var/www/.npm-global/bin:$PATH

curl -sL https://rpm.nodesource.com/setup_11.x | sudo -E bash -
yum install -y --enablerepo=nodesource nodejs

npm install -g autoprefixer clean-css-cli nodemon npm-run-all postcss-cli postcss-discard-empty shx uglify-js
npm install -g -f --unsafe-perm node-sass
npm config set prefix '/var/www/.npm-global'
chmod 2770 /var/www/.npmrc
chown apache.apache /var/www/.npmrc
chmod -Rf 2770 /var/www/.npm
chown -Rf apache.apache /var/www/.npm
chmod -Rf 2770 /var/www/.npm-global
chown -Rf apache.apache /var/www/.npm-global

#Install Composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/bin/composer

#Install IonCube
wget http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
tar -xzf ioncube_loaders_lin_x86-64.tar.gz
cd ioncube/
cp ioncube_loader_lin_7.4.so /opt/remi/php74/root/usr/lib64/php/modules/

#Configure php.ini
echo "short_open_tag = On" >> /etc/opt/remi/php74/php.ini
echo "expose_php = Off" >>/etc/opt/remi/php74/php.ini
echo "max_execution_time = 90" >>/etc/opt/remi/php74/php.ini
echo "max_input_time = 90" >>/etc/opt/remi/php74/php.ini
echo "error_reporting = E_ALL & ~E_DEPRECATED & ~E_NOTICE & ~E_STRICT & ~E_WARNING" >>/etc/opt/remi/php74/php.ini
echo "post_max_size = 60M" >>/etc/opt/remi/php74/php.ini
echo "upload_max_filesize = 60M" >>/etc/opt/remi/php74/php.ini
#echo "allow_url_fopen = Off" >>/etc/opt/remi/php74/php.ini
echo "date.timezone = UTC" >>/etc/opt/remi/php74/php.ini
echo "realpath_cache_size = 1M" >>/etc/opt/remi/php74/php.ini
echo "session.cookie_httponly = 1" >>/etc/opt/remi/php74/php.ini
echo "[apcu]" >>/etc/opt/remi/php74/php.ini
echo "apc.enabled=1" >>/etc/opt/remi/php74/php.ini
echo "apc.shm_size=32M" >>/etc/opt/remi/php74/php.ini
echo "apc.ttl=7200" >>/etc/opt/remi/php74/php.ini
echo "apc.enable_cli=0" >>/etc/opt/remi/php74/php.ini
echo "apc.serializer=php" >>/etc/opt/remi/php74/php.ini
echo "apc.stat=0" >>/etc/opt/remi/php74/php.ini
echo "[custom]" >>/etc/opt/remi/php74/php.ini
echo "realpath_cache_ttl = 7200" >>/etc/opt/remi/php74/php.ini
echo "realpath_cache_size = 4096k" >>/etc/opt/remi/php74/php.ini
echo "opcache.enable=1" >>/etc/opt/remi/php74/php.ini
echo "opcache.memory_consumption=128" >>/etc/opt/remi/php74/php.ini
echo "opcache.max_accelerated_files=4000" >>/etc/opt/remi/php74/php.ini
echo "opcache_revalidate_freq = 240" >>/etc/opt/remi/php74/php.ini
echo "zend_extension=/opt/remi/php74/root/usr/lib64/php/modules/ioncube_loader_lin_7.4.so" >>/etc/opt/remi/php74/php.ini

#Activate
service httpd restart

#Cleanup
rm -Rf /root/.ssh
rm -Rf /home/ec2-user/.ssh