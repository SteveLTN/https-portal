From nginx

MAINTAINER Weiyan Shao "lighteningman@gmail.com"

WORKDIR /root

RUN mkdir -p /var/www/challenges/ && \
    apt-get update && \
    apt-get install -y python ruby wget cron && \
    rm -rf /var/lib/apt/lists/*

COPY ./bin/acme_tiny /usr/local/bin/acme_tiny
COPY ./bin/renew_certs /etc/cron.monthly/renew_certs
COPY ./bin/entrypoint /usr/local/bin/entrypoint
COPY ./certs_manager /opt/certs_manager

RUN chmod a+x /usr/local/bin/acme_tiny && \
    chmod a+x /etc/cron.monthly/renew_certs && \
    chmod a+x /usr/local/bin/entrypoint

VOLUME /var/lib/nginx-acme
RUN mkdir -p /var/lib/nginx-acme

COPY ./nginx-conf /var/lib/nginx-conf

ENTRYPOINT /usr/local/bin/entrypoint
