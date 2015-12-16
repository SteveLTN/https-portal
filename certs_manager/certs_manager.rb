Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file }
require_relative 'models/domain'

class CertsManager
  include Commands

  def entrypoint
    OpenSSL.gen_account_key
    download_intermediate_cert
    Nginx.start

    NAConfig.domains.each do |domain|
      mkdir(domain)
      OpenSSL.gen_domain_key(domain)
      OpenSSL.create_csr(domain)
      Nginx.config_http(domain)
      ACME.sign(domain)
      chain_keys(domain)
      Nginx.config_ssl(domain)
    end

    start_cron
    sleep
  end

  def renew
    download_intermediate_cert

    NAConfig.domains.each do |domain|
      ACME.sign(domain)
      chain_keys(domain)
    end

    Nginx.reload
  end
end
