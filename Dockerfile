FROM nginx

MAINTAINER Weiyan Shao "lighteningman@gmail.com"

WORKDIR /root

RUN rm /etc/nginx/conf.d/default.conf
ENV DOCKER_GEN_VERSION 0.4.2

RUN mkdir -p /var/www/challenges/ && \
    apt-get update && \
    apt-get install -y python ruby cron wget && \
    wget -q https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz && \
    tar -C /usr/local/bin -xvzf docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz && \
    rm docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz && \
    apt-get remove -y wget &&\
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY ./bin/acme_tiny ./bin/setup ./bin/init ./bin/reconfig /usr/local/bin/
COPY ./bin/renew_certs /etc/cron.weekly/renew_certs
COPY ./certs_manager /opt/certs_manager
COPY ./docker-gen.tmpl /etc/docker-gen/domains.tmpl


RUN chmod a+x /usr/local/bin/* && \
    chmod a+x /etc/cron.weekly/renew_certs

VOLUME /var/lib/nginx-acme

COPY ./nginx-conf /var/lib/nginx-conf

ENTRYPOINT ["/usr/local/bin/init"]
