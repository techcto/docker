FROM php:8.1-fpm-alpine3.17


ENV TIDY_VERSION=5.1.25
RUN apk update

RUN set -ex; \
	apk add --no-cache --virtual .build-deps \
		autoconf \
		build-base \
		gettext-dev \
		freetype-dev \
		libjpeg-turbo-dev \
		libpng-dev \
		libtool \
		libxml2-dev \
		libxslt-dev \
		libssh2-dev \
		libssh2 \
		openldap-dev \
		python3 \
		npm \
		bash \
		git \
		sed \
		yaml \
		yaml-dev \
		pcre-dev \
		tidyhtml-dev \
		libbz2 \
		bzip2-dev \
		libintl \
		gettext \
		nss postfix rsyslog \
        zip libzip-dev unzip wget curl ;

# RUN cd /root && wget https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz && tar -xvzf ioncube_loaders_lin_x86-64.tar.gz;
# RUN	mkdir -p /usr/local/php/ext/ioncube && cd /root/ioncube && cp ioncube_loader_lin_8.1.so /usr/local/php/ext/ioncube/ && rm -Rf /root/ioncube;
RUN	mkdir -p /usr/local/php/ext/ioncube
COPY ./ioncube_loader_alpine_8.1_12.0.5.so /usr/local/php/ext/ioncube/ioncube_loader_lin_8.1.so

RUN docker-php-ext-configure zip;
RUN docker-php-ext-install \
		bcmath \	
		bz2 \
		calendar \
		dba \
		exif \
		gettext \
		ldap \
		mysqli \
		pdo_mysql \
		shmop \
		soap \
		sockets \
		sysvmsg \
		sysvsem \
		sysvshm \
		tidy \
		# wddx \
		xsl \
		zip \
	; \
	pecl install \
        apcu \
        oauth \
		yaml \
		redis \
		xdebug \
	; \
	pecl install ssh2-1.3.1; \
	docker-php-ext-enable \
        oauth \
		redis \
		ssh2 \
		yaml \
	; \
	rm -rf /tmp/pear ~/.pearrc; \
	php --version

RUN pecl install mongodb; \
	docker-php-ext-enable mongodb; \
	apk add mongodb-tools

RUN docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/; \
	docker-php-ext-install gd

#Install Composer.
COPY ./composer.sh ./composer.sh
RUN sh composer.sh --install-dir=/usr/local/bin --filename=composer \
    && rm -rf composer.sh

COPY ./php.ini /usr/local/etc/php/php.ini
COPY ./php-fpm.conf /usr/local/etc/php-fpm.conf

#NPM
RUN mkdir -p "/var/www/node_modules_global" \
    && mkdir -p "/var/www/.npm" \
    && npm config set prefix "/var/www/node_modules_global" \
    && npm install -g --unsafe-perm @fortawesome/fontawesome-free autoprefixer clean-css-cli node-sass npm-run-all postcss postcss-cli gulp gulp-autoprefixer \
		gulp-clean gulp-clean-css gulp-concat gulp-rename gulp-sass gulp-uglify node-sass \
    && chown -Rf www-data.www-data "/var/www/node_modules_global" "/var/www/.npm" \
    && chmod -Rf 2770 "/var/www/node_modules_global" "/var/www/.npm"

#Remove useless config
RUN rm -rf /etc/php8/php-fpm.d