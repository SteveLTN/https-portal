FROM node:12-alpine AS builder
COPY api/package*.json /src/api/
RUN npm install --prefix=/src/api/
COPY ./api /src/api
RUN npm run build --prefix=/src/api/


FROM nginx:1.17.3
ARG  ARCH=amd64

# Delete sym links from nginx image, install logrotate
RUN rm /var/log/nginx/access.log && \
    rm /var/log/nginx/error.log

WORKDIR /root

ENV S6_OVERLAY_VERSION v1.22.1.0
ENV ACME_TINY_VERSION 4.1.0
ENV NODE_VERSION=12.6.0
ENV NVM_DIR=/root/.nvm

ADD https://github.com/just-containers/s6-overlay/releases/download/$S6_OVERLAY_VERSION/s6-overlay-$ARCH.tar.gz /tmp/
ADD https://raw.githubusercontent.com/diafygi/acme-tiny/$ACME_TINY_VERSION/acme_tiny.py /bin/acme_tiny

RUN tar xzf /tmp/s6-overlay-$ARCH.tar.gz -C / && \
    rm /tmp/s6-overlay-$ARCH.tar.gz && \
    rm /etc/nginx/conf.d/default.conf && \
    apt-get update && \
    apt-get install -y curl ruby ruby-rest-client cron iproute2 apache2-utils logrotate && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /src/api


COPY ./fs_overlay /

RUN mkdir -p $NVM_DIR
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
ENV PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"

COPY --from=builder /src/api/dist /src/api/dist
COPY api/package*.json /src/api/
RUN npm install --production --prefix=/src/api/
RUN chmod a+x /bin/*

VOLUME /var/lib/https-portal
VOLUME /var/log/nginx

ENTRYPOINT ["/init"]
