ARG  DIST=nginx:1.23.1
FROM $DIST

# Set by `docker buildx build`
ARG  TARGETPLATFORM

# Delete sym links from nginx image, install logrotate
RUN rm /var/log/nginx/access.log && \
    rm /var/log/nginx/error.log

WORKDIR /root

RUN apt-get clean && \
    apt-get update && \
    apt-get install -y python ruby cron iproute2 apache2-utils logrotate wget inotify-tools && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Need this already now, but cannot copy remainder of fs_overlay yet
COPY ./fs_overlay/bin/archname /bin/

ENV S6_OVERLAY_VERSION v2.1.0.2
ENV DOCKER_GEN_VERSION 0.7.4
ENV ACME_TINY_VERSION 4.1.0

RUN sh -c "wget -q https://github.com/just-containers/s6-overlay/releases/download/$S6_OVERLAY_VERSION/s6-overlay-`archname s6-overlay`.tar.gz -O /tmp/s6-overlay.tar.gz" && \
    tar xzf /tmp/s6-overlay.tar.gz -C / && \
    rm -rf /tmp/s6-overlay.tar.gz
RUN sh -c "wget -q https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-linux-`archname docker-gen`-$DOCKER_GEN_VERSION.tar.gz -O /tmp/docker-gen.tar.gz" && \
    tar xzf /tmp/docker-gen.tar.gz -C /bin && \
    rm -rf /tmp/docker-gen.tar.gz

# Bring the container down if stage fails
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2

RUN wget -q https://raw.githubusercontent.com/diafygi/acme-tiny/$ACME_TINY_VERSION/acme_tiny.py -O /bin/acme_tiny

RUN rm /etc/nginx/conf.d/default.conf /etc/crontab

COPY ./fs_overlay /

RUN chmod a+x /bin/* && \
    chmod 0644 /etc/logrotate.d/nginx

VOLUME /var/lib/https-portal
VOLUME /var/log/nginx


# HEALTHCHECK --interval=5s --timeout=3s --start-period=10s --retries=3 CMD wget -q -O /dev/null http://localhost:80/ || exit 1

HEALTHCHECK --interval=5s --timeout=1s --start-period=2s --retries=20 CMD   service nginx status || exit 1

ENTRYPOINT ["/init"]
