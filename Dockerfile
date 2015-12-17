FROM nginx

MAINTAINER Weiyan Shao "lighteningman@gmail.com"

WORKDIR /root

RUN rm /etc/nginx/conf.d/default.conf

RUN mkdir -p /var/www/challenges/ && \
    apt-get update && \
    apt-get install -y python ruby cron && \
    rm -rf /var/lib/apt/lists/*

COPY ./bin/acme_tiny ./bin/setup ./bin/init /usr/local/bin/
COPY ./bin/renew_certs /etc/cron.weekly/renew_certs

COPY ./certs_manager /opt/certs_manager

RUN chmod a+x /usr/local/bin/* && \
    chmod a+x /etc/cron.weekly/renew_certs

VOLUME /var/lib/nginx-acme

COPY ./nginx-conf /var/lib/nginx-conf

ENTRYPOINT ["/usr/local/bin/init"]
