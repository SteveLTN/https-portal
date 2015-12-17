require 'date'

module OpenSSL
  def self.ensure_account_key
    unless File.exist? "/var/lib/nginx-acme/account.key"
      system 'openssl genrsa 4096 > /var/lib/nginx-acme/account.key'
    end
  end

  def self.ensure_domain_key(domain)
    unless File.exist? domain.key_path
      system "openssl genrsa 2048 > #{domain.key_path}"
    end
  end

  def self.create_csr(domain)
    system "openssl req -new -sha256 -key #{domain.key_path} -subj '/CN=#{domain.name}' > #{domain.csr_path}"
  end

  def self.need_to_sign_or_renew?(domain)
    return true if NAConfig.force_renew?

    skip_conditions = File.exist?(domain.key_path) &&
                      File.exist?(domain.chained_cert_path) &&
                      expires_in_days(domain.chained_cert_path) > 30

    !skip_conditions
  end

  def self.expires_in_days(pem)
    (expires_at(pem) - Date.today).to_i
  end

  private

  def self.expires_at(pem)
    date_str = `openssl x509 -enddate -noout -in #{pem}`.sub('notAfter=', '')
    Date.parse date_str
  end
end
