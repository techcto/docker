FROM 'redis:alpine'
RUN echo "net.core.somaxconn = 511" >> /etc/sysctl.conf
RUN echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
CMD [ "redis-server"]