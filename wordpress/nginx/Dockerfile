FROM 'nginx:alpine'

COPY ./nginx.conf /etc/nginx/conf.d/nginx.conf

#Entrypoint
COPY ./nginx-entrypoint.sh /docker-entrypoint.sh
RUN chmod a+rx /docker-entrypoint.sh
ENTRYPOINT ["sh", "/docker-entrypoint.sh"]