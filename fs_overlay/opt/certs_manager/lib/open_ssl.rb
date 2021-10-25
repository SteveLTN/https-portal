require 'date'

module OpenSSL
  def self.ensure_account_key
    path = "#{NAConfig.portal_base_dir}/account.key"
    unless File.exist?(path) && system("openssl rsa --in #{path} --noout --check")
      system "openssl genrsa 4096 > #{path}"
    end
  end

  def self.create_ongoing_domain_key(domain)
    algo = NAConfig.certificate_algorithm
    Logger.debug "create_ongoing_domain_key #{algo} for #{domain.name}"
    if algo == "rsa"
      system "openssl genrsa #{NAConfig.key_length} > #{domain.ongoing_key_path}"
    else
      system "openssl ecparam -genkey -name #{algo} -noout -out #{domain.ongoing_key_path}"
    end
  end

  def self.create_csr(domain)
    Logger.debug "create_csr for #{domain.name}"
    system "openssl req -new -sha256 -key #{domain.ongoing_key_path} -subj '/CN=#{domain.name}' > #{domain.csr_path}"
  end

  def self.key_and_cert_exist?(domain)
    File.exist?(domain.key_path) && File.exist?(domain.signed_cert_path)
  end

  def self.need_to_sign_or_renew?(domain)
    return true if NAConfig.force_renew?

    skip_conditions = File.exist?(domain.key_path) &&
                      File.exist?(domain.signed_cert_path) &&
                      !dummy?(domain.signed_cert_path) &&
                      expires_in_days(domain.signed_cert_path) > NAConfig.renew_margin_days

    !skip_conditions
  end

  def self.expires_in_days(pem)
    (expires_at(pem) - Date.today).to_i
  end

  def self.ensure_dhparam
    unless dhparam_valid?(NAConfig.dhparam_path)
      system "mkdir -p #{File.dirname(NAConfig.dhparam_path)} && openssl dhparam -out #{NAConfig.dhparam_path} 2048"
    end
  end

  def self.self_sign(domain)
    puts "Self-signing test certificate for #{domain.name}"

    command = <<-EOC
    openssl req -x509 \
      -newkey rsa:#{NAConfig.key_length} \
      -nodes \
      -out #{domain.ongoing_cert_path} \
      -keyout #{domain.ongoing_key_path} \
      -days 90 \
      -batch \
      -subj "/CN=#{domain.name}" \
      -addext "extendedKeyUsage = serverAuth"
    EOC

    (system command) && ACME.rename_ongoing_cert_and_key(domain)
  end

  private

  def self.dummy?(pem)
    issuer = `openssl x509 -issuer -noout -in #{pem}`
    issuer.include? "default-server.example.com"
  end

  def self.expires_at(pem)
    date_str = `openssl x509 -enddate -noout -in #{pem}`.sub('notAfter=', '')
    Date.parse date_str
  end

  def self.dhparam_valid?(path)
    File.exist?(path) && system("openssl dhparam -check < #{path}")
  end
end
