require 'date'

module OpenSSL
  def self.ensure_account_key
    unless File.exist? '/var/lib/https-portal/account.key'
      system 'openssl genrsa 4096 > /var/lib/https-portal/account.key'
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

  def self.ensure_dhparam
    unless File.exist? NAConfig.dhparam_path
      system "mkdir -p #{File.dirname(NAConfig.dhparam_path)} && openssl dhparam -out #{NAConfig.dhparam_path} 2048"
    end
  end

  def self.self_sign(domain)
    puts "Self-signing test certificate for #{domain.name}"

    ensure_domain_key(domain)

    command = <<-EOC
    openssl x509 -req -days 90 \
      -in #{domain.csr_path} \
      -signkey #{domain.key_path} \
      -out #{domain.signed_cert_path}
    EOC

    system command

    system "cp #{domain.signed_cert_path} #{domain.chained_cert_path}"
  end

  private

  def self.expires_at(pem)
    date_str = `openssl x509 -enddate -noout -in #{pem}`.sub('notAfter=', '')
    Date.parse date_str
  end
end
