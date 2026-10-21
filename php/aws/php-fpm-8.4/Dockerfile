FROM amazonlinux:2023

COPY verify-php-security.sh /usr/local/bin/verify-php-security.sh
COPY init.sh /init.sh
RUN chmod +x /init.sh
RUN /init.sh && sh /usr/local/bin/verify-php-security.sh
