module Commands
  def download_intermediate_cert
    system 'wget -q -O - https://letsencrypt.org/certs/lets-encrypt-x1-cross-signed.pem > /var/lib/nginx-acme/intermediate.pem'
  end

  def chain_keys(domain)
    system "cat #{domain.signed_cert_path} /var/lib/nginx-acme/intermediate.pem > #{domain.chained_cert_path}"
  end

  def start_cron
    system 'cron'
  end

  def mkdir(domain)
    system "mkdir -p #{domain.dir}"
  end
end
