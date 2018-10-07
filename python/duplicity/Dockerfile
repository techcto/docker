FROM alpine:3.7

ARG DUPLICITY_VERSION=latest

RUN apk upgrade --update && \
    apk add \
      tzdata \
      openssh \
      openssl \
      duply \
      ca-certificates \
      python-dev \
      libffi-dev \
      openssl-dev \
      gcc \
      alpine-sdk \
      linux-headers \
      musl-dev \
      mysql \
      mysql-client \
      mongodb-tools \
      perl \
      rsync \
      lftp \
      py-pip && \
    # Install Duplicity
    if  [ "${DUPLICITY_VERSION}" = "latest" ]; \
      then apk add duplicity ; \
      else apk add "duplicity=${DUPLICITY_VERSION}" ; \
    fi && \
    pip install --upgrade pip && \
    pip install \
      fasteners \
      PyDrive \
      chardet \
      azure-storage \
      boto \
      lockfile \
      paramiko \
      pycryptopp \
      python-keystoneclient \
      python-swiftclient \
      requests==2.14.2 \
      requests_oauthlib \
      urllib3 \
      b2 \
      dropbox==6.9.0 && \
    apk add \
      go \
      git \
      curl \
      wget \
      make && \
    # Cleanup
    apk del \
      go \
      git \
      curl \
      wget \
      python-dev \
      libffi-dev \
      openssl-dev \
      openssl \
      alpine-sdk \
      linux-headers \
      gcc \
      musl-dev \
      make && \
    apk add \
      openssl && \
    rm -rf /var/cache/apk/* && rm -rf /tmp/*

COPY init.sh /root/init.sh
RUN chmod +x /root/init.sh

#Entrypoint
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod a+rx /docker-entrypoint.sh
ENTRYPOINT ["sh", "/docker-entrypoint.sh"]