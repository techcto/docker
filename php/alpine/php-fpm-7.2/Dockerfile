FROM php:7.2-fpm-alpine
RUN echo "http://dl-4.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories
RUN echo "http://dl-4.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories

ENV MEMCACHE_VERSION 2.2.0
ENV TIDY_VERSION=5.1.25
RUN apk update

RUN apk add mongodb-tools --repository=http://dl-cdn.alpinelinux.org/alpine/v3.9/community
RUN apk add libc6-compat --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/v3.10/main

RUN set -ex; \
	\
	apk add --no-cache --virtual .build-deps \
		autoconf \
		build-base \
		gettext-dev \
		libjpeg-turbo-dev \
		libpng-dev \
		libtool \
		libxml2-dev \
		libxslt-dev \
		libssh2-dev \
		openldap-dev \
		python \
		npm \
		g++ \
		make \
		linux-headers \
		bash \
		git \
		sed \
		yaml \
		yaml-dev \
		pcre-dev \
		tidyhtml-dev \
		libbz2 \
		bzip2-dev \
		c-client \
        zip unzip wget curl cmake \
	;

RUN cd /root && wget https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz && tar -xvzf ioncube_loaders_lin_x86-64.tar.gz;
RUN	mkdir -p /usr/local/php/ext/ioncube && cd /root/ioncube && cp ioncube_loader_lin_7.2.so /usr/local/php/ext/ioncube/ && rm -Rf /root/ioncube;

RUN \
	docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
	docker-php-ext-install \
		bcmath \	
		bz2 \
		calendar \
		dba \
		exif \
		gd \
		gettext \
		imap \
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
		wddx \
		xsl \
		zip \
	; \
	pecl config-set php_ini /usr/local/etc/php/php.ini; \
	pecl install \
        apcu \
        mongodb \
        oauth \
		yaml \
		redis \
	; \
	echo "\n" | pecl install ssh2-1.0; \
	docker-php-ext-enable \
        mongodb \
        oauth \
		redis \
		ssh2 \
		yaml \
	; \
	docker-php-source delete; \
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --no-cache $runDeps; \
	# update pecl channel definitions https://github.com/docker-library/php/issues/443
	pecl update-channels; \
	rm -rf /tmp/pear ~/.pearrc; \
	# smoke test
	php --version

#Install Composer
COPY ./composer.sh ./composer.sh
RUN sh composer.sh --install-dir=/usr/local/bin --filename=composer \
    && composer global require "hirak/prestissimo:^0.3" \
    && rm -rf composer.sh

COPY ./php.ini /usr/local/etc/php/php.ini
COPY ./php-fpm.conf /usr/local/etc/php-fpm.conf

#NPM
RUN mkdir -p "/var/www/node_modules_global" \
    && mkdir -p "/var/www/.npm" \
    && npm config set prefix "/var/www/node_modules_global" \
    && npm install -g --unsafe-perm @fortawesome/fontawesome-free autoprefixer clean-css-cli gulp gulp-autoprefixer \
		gulp-clean gulp-clean-css gulp-concat gulp-rename gulp-sass gulp-uglify node-sass \
    && chown -Rf www-data.www-data "/var/www/node_modules_global" "/var/www/.npm" \
    && chmod -Rf 2770 "/var/www/node_modules_global" "/var/www/.npm"

#Remove useless config
RUN apk del --no-network .build-deps
RUN rm -rf /etc/php7/php-fpm.d