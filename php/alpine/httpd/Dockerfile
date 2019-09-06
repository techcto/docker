FROM 'httpd:alpine'

#Install base
RUN apk update
RUN set -ex; \
	\
	apk add \
		python \
		php \
		npm \
		bash \
		git \
		g++ \
		make \
		linux-headers \
		sed \
        zip unzip wget curl \
	;

#Configure Node
RUN mkdir -p /var/www/.npm /var/www/.npm-global \
	&& echo 'export NODE_PATH=/var/www/.npm-global/lib/node_modules' >> /var/www/.npmrc \
	&& echo 'export PATH=$PATH:/var/www/.npm-global/bin' >> /var/www/.npmrc \
	&& export PATH=/var/www/.npm-global/bin:$PATH \
	&& npm config set prefix '/var/www/.npm-global' \
	&& chmod 2770 /var/www/.npmrc \
	&& chmod -Rf 2770 /var/www/.npm \
	&& chmod -Rf 2770 /var/www/.npm-global