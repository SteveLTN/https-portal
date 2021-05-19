FROM ruby:2.7.3-alpine AS ruby-builder

RUN apk add --update build-base 

COPY ./Gemfile .
RUN bundle install



FROM node:12-alpine AS node-builder

WORKDIR /src/api/

# Install all deps to build
COPY api/package.json api/yarn.lock ./
RUN yarn install

COPY ./api ./
RUN yarn run build

# Re-install only production for final layer
RUN rm -rf node_modules && yarn install --production



FROM nginx:1.19.6-alpine AS final-stage
ARG TARGETPLATFORM

# Delete sym links from nginx image, install logrotate
RUN rm /var/log/nginx/access.log && \
    rm /var/log/nginx/error.log

WORKDIR /root

ENV S6_OVERLAY_VERSION=v2.2.0.1  \
    ACME_TINY_VERSION=4.1.0  \
# API volume to store domain .txt and .json files
    DOMAINS_DIR=/var/run/domains.d/  \
    FULLDOMAIN_PATH=/var/run/domains.d/fulldomain \
    DAPPMANAGER_SIGN=http://my.dappnode/sign  \
    DAPPMANAGER_DOMAIN=http://my.dappnode/global-envs/DOMAIN \
    DYNAMIC_UPSTREAM=true \
    RESOLVER=127.0.0.11 \
    GLOBAL_RESOLVER=172.33.1.2 \
    DAPPMANAGER_INTERNAL_IP=http://my.dappnode/global-envs/INTERNAL_IP

ADD https://github.com/just-containers/s6-overlay/releases/download/$S6_OVERLAY_VERSION/s6-overlay-amd64.tar.gz /tmp/
ADD https://github.com/just-containers/s6-overlay/releases/download/$S6_OVERLAY_VERSION/s6-overlay-aarch64.tar.gz /tmp/
ADD https://raw.githubusercontent.com/diafygi/acme-tiny/$ACME_TINY_VERSION/acme_tiny.py /bin/acme_tiny

RUN export ARCH=$(echo $TARGETPLATFORM | cut -d'/' -f2 | sed 's/arm64/aarch64/') && \
    tar xzf /tmp/s6-overlay-$ARCH.tar.gz -C / && \
    rm /tmp/s6-overlay-*.tar.gz && \
    rm /etc/nginx/conf.d/default.conf && \
    apk add --update \
    # From original image
    python2 ruby=2.7.3-r0 iproute2 apache2-utils logrotate openssl \
    # For Typescript app
    nodejs \
    && \
    mkdir -p /src/api

ENV GEM_PATH="${GEM_PATH}${GEM_PATH:+:}/usr/local/bundle/"

COPY --from=ruby-builder /usr/local/bundle/ /usr/local/bundle/
COPY ./fs_overlay /
COPY --from=node-builder /src/api/node_modules /src/api/node_modules
COPY --from=node-builder /src/api/dist /src/api/
RUN chmod a+x /bin/*

VOLUME /var/lib/https-portal
VOLUME /var/log/nginx

ENTRYPOINT ["/init"]
