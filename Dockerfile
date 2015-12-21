FROM nginx

MAINTAINER Weiyan Shao "lighteningman@gmail.com"

WORKDIR /root

ENV DOCKER_GEN_VERSION 0.4.2

RUN rm /etc/nginx/conf.d/default.conf && \
    apt-get update && \
    apt-get install -y python ruby cron wget && \
    wget -q https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz && \
    tar -C /bin -xvzf docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz && \
    rm docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz && \
    apt-get remove -y wget &&\
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY ./fs_root /

RUN chmod a+x /bin/* && \
    chmod a+x /etc/cron.weekly/renew_certs

VOLUME /var/lib/nginx-acme

ENTRYPOINT ["/bin/init"]
