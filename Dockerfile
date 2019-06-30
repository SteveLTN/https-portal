FROM nginx:1.17.0

MAINTAINER Weiyan Shao "lighteningman@gmail.com"

WORKDIR /root

ENV S6_OVERLAY_VERSION v1.22.1.0
ENV DOCKER_GEN_VERSION 0.7.4

ADD https://github.com/just-containers/s6-overlay/releases/download/$S6_OVERLAY_VERSION/s6-overlay-amd64.tar.gz /tmp/
ADD https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz /tmp/
ADD https://raw.githubusercontent.com/diafygi/acme-tiny/5350420d35177eda733d85096433a24e55f8d00e/acme_tiny.py /bin/acme_tiny

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
