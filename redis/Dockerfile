FROM 'redis'
RUN echo "vm.swappiness = 0" >> /etc/sysctl.conf
RUN echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
CMD [ "redis-server"]