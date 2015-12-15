module Commands
  def self.gen_keys
    system 'openssl genrsa 4096 > /root/account.key'
    system 'openssl genrsa 4096 > /root/domain.key'
  end

  def self.create_csr
    system 'openssl req -new -sha256 -key /root/domain.key -subj "/CN=nginx-acme.steveltn.me" > /root/domain.csr'
  end

  def self.download_intermediate_cert
    system 'wget -q -O - https://letsencrypt.org/certs/lets-encrypt-x1-cross-signed.pem > /root/intermediate.pem'
  end

  def self.cat_keys
    system 'cat /root/signed.crt /root/intermediate.pem > /root/chained.pem'
  end

  def self.start_cron
    system 'cron'
  end
end
