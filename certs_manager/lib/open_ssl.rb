module OpenSSL
  def self.gen_account_key
    system 'openssl genrsa 4096 > /var/lib/nginx-acme/account.key'
  end

  def self.gen_domain_key(domain)
    system "openssl genrsa 4096 > #{domain.key_path}"
  end

  def self.create_csr(domain)
    system "openssl req -new -sha256 -key #{domain.key_path} -subj '/CN=#{domain.name}' > #{domain.csr_path}"
  end
end
