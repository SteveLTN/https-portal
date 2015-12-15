#!/usr/bin/env sh

acme_tiny.py \
--account-key /root/account.key \
--csr /root/domain.csr \
--ca https://acme-staging.api.letsencrypt.org \
--acme-dir /var/www/challenges/ > /tmp/signed.crt || exit

wget -O - https://letsencrypt.org/certs/lets-encrypt-x1-cross-signed.pem > /root/intermediate.pem

cat /tmp/signed.crt /root/intermediate.pem > /root/chained.pem

nginx -s reload
