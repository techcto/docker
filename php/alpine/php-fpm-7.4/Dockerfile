FROM php:7.4-fpm-alpine3.13

ENV MEMCACHE_VERSION 2.2.0
ENV TIDY_VERSION=5.1.25
RUN apk update

RUN apk add mongodb-tools --repository=http://dl-cdn.alpinelinux.org/alpine/v3.13/community

RUN apk add --no-cache \
		autoconf \
		build-base \
		libcurl \
		libtool \
		libssh2 \
		python3 \
		npm \
		bash \
		git \
		sed \
		yaml \
		libbz2 \
		libintl \
		gettext \
		libpng \
		libjpeg-turbo \
		libssh2-dev \
		libwebp \
		libzip-dev \
		freetype \
		nss \
		openldap-dev \
		postfix \
		rsyslog \
		tidyhtml-dev \
		gettext-dev libxml2-dev libxslt-dev yaml-dev pcre-dev bzip2-dev \
        zip unzip wget curl ;

# RUN cd /root && wget https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz && tar -xvzf ioncube_loaders_lin_x86-64.tar.gz;
COPY ./ioncube_loader_alpine_3_13_7.4_11.0.1.so ./ioncube_loader_alpine_3_13_7.4_11.0.1.so
RUN	mkdir -p /usr/local/php/ext/ioncube && cp ./ioncube_loader_alpine_3_13_7.4_11.0.1.so /usr/local/php/ext/ioncube/ioncube_loader_lin_7.4.so && rm -Rf /root/ioncube;

RUN apk add --no-cache --virtual build-essentials \
	freetype-dev libpng-dev libjpeg-turbo-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd \
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
		xsl \
		zip \
	&& pecl install \
        apcu \
        mongodb \
        oauth \
		yaml \
		redis \
		xdebug \
	&& pecl install ssh2-1.3.1 \
	&& docker-php-ext-enable \
        mongodb \
        oauth \
		redis \
		ssh2 \
		yaml \
	&& apk del build-essentials && rm -rf /usr/src/php* \
	&& php --version

#Install Composer
COPY ./composer.sh ./composer.sh
RUN sh composer.sh --install-dir=/usr/local/bin --filename=composer \
    && rm -rf composer.sh

COPY ./php.ini /usr/local/etc/php/php.ini
COPY ./php-fpm.conf /usr/local/etc/php-fpm.conf

#Remove useless config
RUN rm -rf /etc/php7/php-fpm.d