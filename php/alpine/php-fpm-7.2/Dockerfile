FROM php:7.2-fpm-alpine

RUN echo "http://dl-4.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

ENV MEMCACHE_VERSION 2.2.0
ENV TIDY_VERSION=5.1.25
RUN apk update

RUN set -ex; \
	\
	apk add --no-cache --virtual .build-deps \
		autoconf \
		build-base \
		bzip2-dev \
		gettext-dev \
		icu-dev \
		imagemagick-dev \
		imap-dev \
		libjpeg-turbo-dev \
		libmcrypt-dev \
		libmemcached-dev \
		libpng-dev \
		libssh2-dev \
		libtool \
		libxml2-dev \
		libxslt-dev \
		make \
		mongodb-tools \
		gcc \
		g++ \
		python \
		nodejs \
		nodejs-npm \
		bash \
		git \
		sed \
		openldap-dev \
		pcre-dev \
        zip unzip wget curl cmake \
	;

RUN cd /root && wget https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz && tar -xvzf ioncube_loaders_lin_x86-64.tar.gz;
RUN	mkdir -p /usr/local/php/ext/ioncube && cd /root/ioncube && cp ioncube_loader_lin_7.2.so /usr/local/php/ext/ioncube/;

RUN apk add tidyhtml-dev
RUN npm install --production --silent
RUN pecl install mcrypt-1.0.1;
RUN docker-php-ext-enable mcrypt;

RUN docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
	docker-php-ext-install \
		bcmath \	
		bz2 \
		calendar \
		dba \
		exif \
		gd \
		gettext \
		imap \
		intl \
		ldap \
		mysqli \
		opcache \
		pdo_mysql \
		shmop \
		soap \
		sockets \
		sysvmsg \
		sysvsem \
		sysvshm \
		tidy \
		wddx \
		xmlrpc \
		xsl \ 
		zip \
	; \
	pecl install \
        apcu \
		igbinary \
		imagick \
		memcached \
		msgpack \
        mongodb \
        oauth \
		redis \
	; \
	echo "\n" | pecl install ssh2-1.0; \
	docker-php-ext-enable \
		igbinary \
		imagick \
		msgpack \
        mongodb \
        oauth \
		redis \
		ssh2 \
	; \
	runDeps="$( \
		scanelf --needed --nobanner --recursive \
			/usr/local/lib/php/extensions \
			| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
			| sort -u \
			| xargs -r apk info --installed \
			| sort -u \
	)"; \
	apk add --virtual $runDeps; \
	rm -rf /tmp/pear/;

#Install Composer
COPY ./composer.sh ./composer.sh
RUN sh composer.sh --install-dir=/usr/local/bin --filename=composer \
    && composer global require "hirak/prestissimo:^0.3" \
    && rm -rf composer.sh

COPY ./php.ini /usr/local/etc/php/php.ini
COPY ./php-fpm.conf /usr/local/etc/php-fpm.conf

#Remove useless config
RUN rm -rf /etc/php7/php-fpm.d