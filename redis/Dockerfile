FROM 'redis'
COPY redis.conf /usr/local/etc/redis.conf

RUN echo "vm.swappiness = 0" >> /etc/sysctl.conf
RUN echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
RUN echo "net.core.somaxconn = 511" >> /etc/sysctl.conf

CMD [ "redis-server", "/usr/local/etc/redis.conf" ]