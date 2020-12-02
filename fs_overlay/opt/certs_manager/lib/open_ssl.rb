require 'date'
require 'rest-client'


module OpenSSL
  def self.ensure_account_key
    path = '/var/lib/https-portal/account.key'
    unless File.exist?(path) && system("openssl rsa --in #{path} --noout --check")
      system "openssl genrsa 4096 > #{path}"
    end
  end

  def self.ensure_domain_key(domain)
    unless File.exist?(domain.key_path) && system("openssl rsa --in #{domain.key_path} --noout --check")
      system "openssl genrsa #{ENV['NUMBITS'] =~ /^[0-9]+$/ ? ENV['NUMBITS'] : 2048} > #{domain.key_path}"
    end
  end

  def self.create_csr(domain)
    if domain.stage == 'dappnode-api'
      system "openssl req -new -sha256 -key #{domain.key_path} -subj '/CN=#{domain.name}' -addext 'subjectAltName = *.#{domain.name}' > #{domain.csr_path}"
    else
      system "openssl req -new -sha256 -key #{domain.key_path} -subj '/CN=#{domain.name}' > #{domain.csr_path}"
    end
  end

  def self.need_to_sign_or_renew?(domain)
    return true if NAConfig.force_renew?

    skip_conditions = File.exist?(domain.key_path) &&
                      File.exist?(domain.signed_cert_path) &&
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

    ensure_domain_key(domain)

    command = <<-EOC
    openssl x509 -req -days 90 \
      -in #{domain.csr_path} \
      -signkey #{domain.key_path} \
      -out #{domain.signed_cert_path}
    EOC

    system command
  end

  self.get_eth_signature(timestamp)
    dappmanager_url = ENV['DAPPMANAGER_URL']
    response = RestClient::Request.execute(
      :method => :get,
      url => "http://#{dappmanager_url}/api/sign?message=#{timestamp}"
    )
    results = JSON.parse(response.to_str)
    signature = results['data'][0]['sig']
    address = results['data'][0]['address']
    return signature, address
  end


  def self.api_sign(domain)
    puts "Api call for signing certificate for *.#{domain.name}"
    timestamp = Time.now.to_i
    signature, address = get_eth_signature(timestamp)
    certapi_url = ENV['CERTAPI_URL']

    response = RestClient::Request.execute(
      :method => :post,
      :url => "http://#{certapi_url}/?sig=#{signature}&address=#{address}&timestamp=#{timestamp}",
      :payload => {
        :csr => File.new(domain.csr_path 'rb')
      }
    )
    File.write(domain.signed_cert_path, response.to_str)
  end

  private

  def self.expires_at(pem)
    date_str = `openssl x509 -enddate -noout -in #{pem}`.sub('notAfter=', '')
    Date.parse date_str
  end

  def self.dhparam_valid?(path)
    File.exist?(path) && system("openssl dhparam -check < #{path}")
  end
end
