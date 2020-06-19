ARG  DIST=nginx:1.17.3
FROM $DIST
ARG  ARCH=amd64

# Delete sym links from nginx image, install logrotate
RUN rm /var/log/nginx/access.log && \
    rm /var/log/nginx/error.log && \
    apt-get update && \
    apt-get -y install logrotate

WORKDIR /root

ENV S6_OVERLAY_VERSION v1.22.1.0
ENV DOCKER_GEN_VERSION 0.7.4
ENV ACME_TINY_VERSION 4.1.0

ADD https://github.com/just-containers/s6-overlay/releases/download/$S6_OVERLAY_VERSION/s6-overlay-$ARCH.tar.gz /tmp/
ADD https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-linux-$ARCH-$DOCKER_GEN_VERSION.tar.gz /tmp/
ADD https://raw.githubusercontent.com/diafygi/acme-tiny/$ACME_TINY_VERSION/acme_tiny.py /bin/acme_tiny

RUN tar xzf /tmp/s6-overlay-$ARCH.tar.gz -C / &&\
    tar -C /bin -xzf /tmp/docker-gen-linux-${ARCH}-$DOCKER_GEN_VERSION.tar.gz && \
    rm /tmp/docker-gen-linux-$ARCH-$DOCKER_GEN_VERSION.tar.gz && \
    rm /tmp/s6-overlay-$ARCH.tar.gz && \
    rm /etc/nginx/conf.d/default.conf && \
    apt-get update && \
    apt-get install -y python ruby cron iproute2 apache2-utils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY ./fs_overlay /

RUN chmod a+x /bin/*

VOLUME /var/lib/https-portal
VOLUME /var/log/nginx

ENTRYPOINT ["/init"]
