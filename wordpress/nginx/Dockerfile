FROM 'nginx:alpine'

COPY ./nginx/nginx.conf /etc/nginx/conf.d/nginx.conf

#Entrypoint
COPY ./nginx/nginx-entrypoint.sh /docker-entrypoint.sh
RUN chmod a+rx /docker-entrypoint.sh
ENTRYPOINT ["sh", "/docker-entrypoint.sh"]