class CertsManager
  def entrypoint
    entrypoint_sh = <<-EOS
      openssl genrsa 4096 > /root/account.key

      openssl genrsa 4096 > /root/domain.key

      openssl req -new -sha256 -key /root/domain.key -subj "/CN=nginx-acme.steveltn.me" > /root/domain.csr

      cp /root/nginx-conf/nginx-acme.steveltn.me.conf /etc/nginx/conf.d/ && nginx -q

      acme_tiny.py --account-key /root/account.key --csr /root/domain.csr --acme-dir /var/www/challenges/ --ca https://acme-staging.api.letsencrypt.org > /root/signed.crt

      wget -q -O - https://letsencrypt.org/certs/lets-encrypt-x1-cross-signed.pem > /root/intermediate.pem
      cat /root/signed.crt /root/intermediate.pem > /root/chained.pem

      cp /root/nginx-conf/nginx-acme.steveltn.me.ssl.conf /etc/nginx/conf.d/ && nginx -s reload

      cron
    EOS

    system(entrypoint_sh) && sleep
  end

  def renew
    renew_sh = <<-EOS
      acme_tiny.py \
      --account-key /root/account.key \
      --csr /root/domain.csr \
      --ca https://acme-staging.api.letsencrypt.org \
      --acme-dir /var/www/challenges/ > /tmp/signed.crt || exit

      wget -q -O - https://letsencrypt.org/certs/lets-encrypt-x1-cross-signed.pem > /root/intermediate.pem

      cat /tmp/signed.crt /root/intermediate.pem > /root/chained.pem

      nginx -s reload
    EOS

    system(renew_sh)
  end
end
