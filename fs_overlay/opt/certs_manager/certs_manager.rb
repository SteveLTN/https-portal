Dir[File.dirname(__FILE__) + '/lib/*.rb'].each { |file| require file }
require_relative 'models/domain'

class CertsManager
  include Commands

  attr_accessor :lock

  def setup
    add_dockerhost_to_hosts
    NAConfig.domains.each(&:ensure_welcome_page)

    OpenSSL.ensure_dhparam
    OpenSSL.ensure_account_key
    download_intermediate_cert
    Nginx.setup
    Nginx.start

    ensure_signed(NAConfig.domains)

    Nginx.stop
    sleep 1 # Give Nginx some time to shutdown
  end

  def renew
    obtain_lock

    download_intermediate_cert

    NAConfig.domains.each do |domain|
      if OpenSSL.need_to_sign_or_renew? domain
        ACME.sign(domain)
        chain_keys(domain)
        Nginx.reload
        puts "Renewed certs for #{domain.name}"
      else
        puts "No need to renew certs for #{domain.name}, it will not expire in #{OpenSSL.expires_in_days(domain.chained_cert_path)} days."
      end
    end
  ensure
    release_lock
  end

  def reconfig
    ensure_signed(NAConfig.auto_discovered_domains)
  end

  private

  def ensure_signed(domains)
    obtain_lock

    domains.each do |domain|
      Nginx.config_http(domain)

      if OpenSSL.need_to_sign_or_renew? domain
        mkdir(domain)
        OpenSSL.ensure_domain_key(domain)
        OpenSSL.create_csr(domain)
        if ACME.sign(domain)
          chain_keys(domain)
          Nginx.config_ssl(domain)
          puts "Signed key for #{domain.name}"
        else
          puts("Failed to obtain certs for #{domain.name}")
        end
      else
        Nginx.config_ssl(domain)
        puts "No need to re-sign certs for #{domain.name}, it will not expire in #{OpenSSL.expires_in_days(domain.chained_cert_path)} days."
      end
    end
  ensure
    release_lock
  end

  def obtain_lock
    self.lock = File.open('/tmp/https-portal.lock', File::CREAT)

    lock.flock File::LOCK_EX
  end

  def release_lock
    lock.flock File::LOCK_UN
    lock.close
  end
end
