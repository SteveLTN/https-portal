Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file }
require_relative 'models/domain'

class CertsManager
  include Commands

  def setup
    add_dockerhost_to_hosts
    OpenSSL.gen_dhparam
    OpenSSL.ensure_account_key
    download_intermediate_cert
    Nginx.start

    ensure_signed(NAConfig.domains)

    start_cron
  end

  def renew
    download_intermediate_cert

    NAConfig.domains.each do |domain|
      if OpenSSL.need_to_sign_or_renew? domain
        ACME.sign(domain)
        chain_keys(domain)
        Nginx.reload
        puts "Renewed certs for #{domain.name}"
      else
        puts "No need to renew certs for #{domain.name}, it will not expire until #{OpenSSL.expires_in_days(domain.chained_cert_path)} days from now."
      end
    end

  end

  def reconfig
    ensure_signed(NAConfig.auto_discovered_domains)
  end

  def ensure_signed(domains)
    domains.each do |domain|
      Nginx.config_http(domain)

      if OpenSSL.need_to_sign_or_renew? domain
        mkdir(domain)
        OpenSSL.ensure_domain_key(domain)
        OpenSSL.create_csr(domain)
        ACME.sign(domain)
        chain_keys(domain)
        puts "Signed key for #{domain.name}"
      else
        puts "No need to re-sign certs for #{domain.name}, it will not expire until #{OpenSSL.expires_in_days(domain.chained_cert_path)} days from now."
      end

      Nginx.config_ssl(domain)
    end
  end
end
