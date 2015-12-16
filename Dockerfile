From nginx

MAINTAINER Weiyan Shao "lighteningman@gmail.com"

WORKDIR /root

RUN mkdir -p /var/www/challenges/ && \
    apt-get update && \
    apt-get install -y python ruby wget cron && \
    rm -rf /var/lib/apt/lists/*

COPY ./scripts/acme_tiny.py /usr/local/bin/acme_tiny.py
COPY ./scripts/renew_certs.rb /etc/cron.monthly/renew_certs
COPY ./scripts/entrypoint.rb /usr/local/bin/entrypoint.rb
COPY ./certs_manager /opt/certs_manager

RUN chmod a+x /usr/local/bin/acme_tiny.py && \
    chmod a+x /etc/cron.monthly/renew_certs && \
    chmod a+x /usr/local/bin/entrypoint.rb

VOLUME /var/lib/nginx-acme
RUN mkdir -p /var/lib/nginx-acme

COPY ./nginx-conf /var/lib/nginx-conf

ENTRYPOINT /usr/local/bin/entrypoint.rb
