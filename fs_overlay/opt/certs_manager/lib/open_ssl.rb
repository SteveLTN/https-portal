require 'date'
require 'rest-client'
require 'json'


module OpenSSL
  def self.ensure_account_key
    path = "#{NAConfig.portal_base_dir}/account.key"
    unless File.exist?(path) && system("openssl rsa --in #{path} --noout --check")
      system "openssl genrsa 4096 > #{path}"
    end
  end

  def self.ensure_domain_key(domain)
    unless File.exist?(domain.key_path) && system("openssl rsa --in #{domain.key_path} --noout --check")
      system "openssl genrsa #{NAConfig.key_length} > #{domain.key_path}"
    end
  end

  def self.create_csr(domain)
    if domain.stage == 'dappnode-api'
      system "openssl req -new -sha256 -key #{domain.key_path} -subj '/CN=#{domain.global}' -addext 'subjectAltName = DNS:*.#{domain.global}' > #{domain.csr_path}"
    else
      system "openssl req -new -sha256 -key #{domain.key_path} -subj '/CN=#{domain.name}' > #{domain.csr_path}"
    end
  end

  def self.need_to_sign_or_renew?(domain)
    return true if NAConfig.force_renew?

    if File.exist?(domain.key_path) && File.exist?(domain.signed_cert_path)
      cert_pubkey =  `openssl x509 -pubkey -noout -in #{domain.signed_cert_path}`
      priv_pubkey =  `openssl rsa -in #{domain.key_path} -pubout`
    else
      return true
    end

    skip_conditions = expires_in_days(domain.signed_cert_path) > NAConfig.renew_margin_days &&
                      cert_pubkey == priv_pubkey

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

  def self.get_eth_signature(timestamp)
    response = RestClient.post('http://172.33.1.7/sign', timestamp.to_s, :content_type => 'text/plain')

    raise("Failed to get DNP_DAPPMANAGER signature: #{response.to_str}") unless response.code == 200

    results = JSON.parse(response.to_str)
    [results['signature'], results['address']]
  end

  def self.send_api_request(domain, certapi_url, signature, name, address, timestamp, force)
    puts "Api call for signing certificate for *.#{domain.global}"
    response = RestClient::Request.execute(method: :post,
      url: "http://#{certapi_url}/?signature=#{signature}&signer=#{name}&address=#{address}&timestamp=#{timestamp}&force=#{force}",
      timeout: 120,
      payload: { csr: File.new(domain.csr_path, 'rb') })
    raise "An error occured during API call to the signing service: #{response.to_str}" unless response.code == 200
    File.write(domain.signed_cert_path, response.to_str)
    system "test ! -e #{domain.chained_cert_path} && ln -s #{domain.signed_cert_path} #{domain.chained_cert_path}"
  end

  def self.api_sign(domain)
    timestamp = Time.now.to_i
    signature, address = get_eth_signature(timestamp)
    certapi_url = ENV['CERTAPI_URL']
    name = 'https-portal.dnp.dappnode.eth'
    force = ENV['FORCE'] || 0
    send_api_request(domain, certapi_url, signature, name, address, timestamp, force)
    cert_pubkey =  `openssl x509 -pubkey -noout -in #{domain.signed_cert_path}`
    priv_pubkey =  `openssl rsa -in #{domain.key_path} -pubout`
    unless cert_pubkey == priv_pubkey
      puts 'Keys do not match, trying forcing certification service'
      send_api_request(domain, certapi_url, signature, name, address, timestamp, 1)
    end

    puts 'Certificate signed!'
    true
  end

  def self.generate_dummy_certificate(dir, out_path, keyout_path)
    puts "Generating dummy certificate for default fallback server"

    command = <<-EOC
      mkdir -p #{dir} && \
      openssl req -x509 -newkey \
        rsa:#{NAConfig.key_length} -nodes \
        -out #{out_path} \
        -keyout #{keyout_path} \
        -days 36500 \
        -batch \
        -subj "/CN=default-server.example.com"
    EOC

    system command
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
