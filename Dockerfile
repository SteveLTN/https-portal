FROM nginx:1.15.10

MAINTAINER Weiyan Shao "lighteningman@gmail.com"

WORKDIR /root

ENV DOCKER_GEN_VERSION 0.7.3

ADD https://github.com/just-containers/s6-overlay/releases/download/v1.11.0.1/s6-overlay-amd64.tar.gz /tmp/
ADD https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz /tmp/
ADD https://raw.githubusercontent.com/diafygi/acme-tiny/ad7802f1c47e5c31a8e7dfedb3577e6c7d04844a/acme_tiny.py /bin/acme_tiny

RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C / &&\
    tar -C /bin -xzf /tmp/docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz && \
    rm /tmp/docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz && \
    rm /tmp/s6-overlay-amd64.tar.gz && \
    rm /etc/nginx/conf.d/default.conf && \
    apt-get update && \
    apt-get install -y python ruby cron iproute2 apache2-utils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY ./fs_overlay /

RUN chmod a+x /bin/*

VOLUME /var/lib/https-portal

ENTRYPOINT ["/init"]
