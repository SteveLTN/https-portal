#!/usr/bin/env sh

openssl genrsa 4096 > account.key

openssl genrsa 4096 > domain.key

openssl req -new -sha256 -key domain.key -subj "/CN=nginx-acme.steveltn.me" > domain.csr

cp nginx-conf/nginx-acme.steveltn.me.conf /etc/nginx/conf.d/ && nginx -q

acme_tiny --account-key ./account.key --csr ./domain.csr --acme-dir /var/www/challenges/ --ca https://acme-staging.api.letsencrypt.org > ./signed.crt

wget -O - https://letsencrypt.org/certs/lets-encrypt-x1-cross-signed.pem > intermediate.pem
cat signed.crt intermediate.pem > chained.pem

cp nginx-conf/nginx-acme.steveltn.me.ssl.conf /etc/nginx/conf.d/ && nginx -s reload

sleep infinity
