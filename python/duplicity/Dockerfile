FROM amazonlinux:2

COPY init.sh /init.sh
RUN chmod +x /init.sh
RUN /init.sh

#Entrypoint
COPY ./docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod a+rx /docker-entrypoint.sh
ENTRYPOINT ["sh", "/docker-entrypoint.sh"]