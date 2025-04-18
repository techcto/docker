FROM php:8.1-fpm-alpine3.21

ENV TIDY_VERSION=5.1.25
RUN apk update && apk upgrade

RUN set -ex; \
	apk add --no-cache --virtual .build-deps \
	aws-cli \
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
	bash \
	rsync \
	mysql-client \
	mariadb-connector-c \
	sed \
	jq \
	yaml \
	yaml-dev \
	pcre-dev \
	tidyhtml-dev \
	libbz2 \
	bzip2-dev \
	libintl \
	gettext \
	nss postfix rsyslog \
	zip libzip-dev unzip wget ;

# get latest of these (regular apk version has vulnerabilities)
RUN apk del openssl && \ 
	apk add --no-cache -X https://dl-cdn.alpinelinux.org/alpine/edge/main git openssl curl nodejs && \
	apk add --no-cache -X https://dl-cdn.alpinelinux.org/alpine/edge/community npm

RUN docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg;
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
	gd \
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
	docker-php-ext-enable mongodb;
RUN apk add --no-cache -X https://dl-cdn.alpinelinux.org/alpine/edge/community mongodb-tools
RUN npm install -g mongosh

# Create a symlink to rename 'mongosh' to 'mongo'
RUN ln -s /usr/local/bin/mongosh /usr/local/bin/mongo

# RUN cd /root && wget https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz && tar -xvzf ioncube_loaders_lin_x86-64.tar.gz;
# RUN	mkdir -p /usr/local/php/ext/ioncube && cd /root/ioncube && cp ioncube_loader_lin_8.1.so /usr/local/php/ext/ioncube/ && rm -Rf /root/ioncube;
RUN	mkdir -p /usr/local/php/ext/ioncube
COPY ./ioncube_loader_alpine_8.1_12.0.5.so /usr/local/php/ext/ioncube/ioncube_loader_lin_8.1.so

#Install Composer
RUN wget https://getcomposer.org/installer -O composer-setup.php
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer && rm -rf composer-setup.php

COPY ./php.ini /usr/local/etc/php/php.ini
COPY ./php-fpm.conf /usr/local/etc/php-fpm.conf

#Remove useless config
RUN rm -rf /etc/php8/php-fpm.d