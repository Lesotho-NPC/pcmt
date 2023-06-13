FROM akeneo/pim-php-dev:6.0
RUN apt-get update && apt-get install -y openssh-server apache2 supervisor && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /var/lock/apache2 /var/run/apache2 /var/run/sshd /var/log/supervisor
RUN > /var/log/supervisor/akeneo_daemon.err.log
RUN > /var/log/supervisor/akeneo_daemon.out.log

COPY scripts/akeneo_queue_daemon.conf /etc/supervisor/conf.d/akeneo_queue_daemon.conf

EXPOSE 22 80
CMD ["/usr/bin/supervisord"]