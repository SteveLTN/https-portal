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
    Nginx.setup
    Nginx.start

    ensure_signed(NAConfig.domains)

    Nginx.stop
    sleep 1 # Give Nginx some time to shutdown
  end

  def renew
    puts "Renewing ..."
    with_lock do
      NAConfig.domains.each do |domain|
        if OpenSSL.need_to_sign_or_renew? domain
          ACME.sign(domain)
          Nginx.reload
          puts "Renewed certs for #{domain.name}"
        else
          puts "Renewal skipped for #{domain.name}, it expires at #{OpenSSL.expires_in_days(domain.signed_cert_path)} days from now."
        end
      end
    end
    puts "Renewal done."
  end

  def reconfig
    ensure_signed(NAConfig.auto_discovered_domains)
  end

  private

  def ensure_signed(domains)
    with_lock do
      domains.each do |domain|
        Nginx.config_http(domain)

        if OpenSSL.need_to_sign_or_renew? domain
          mkdir(domain)
          OpenSSL.ensure_domain_key(domain)
          OpenSSL.create_csr(domain)
          if ACME.sign(domain)
            Nginx.config_ssl(domain)
            puts "Signed key for #{domain.name}"
          else
            puts("Failed to obtain certs for #{domain.name}")
          end
        else
          Nginx.config_ssl(domain)
          puts "Signing skipped for #{domain.name}, it expires at #{OpenSSL.expires_in_days(domain.signed_cert_path)} days from now."
        end
      end
    end
  end

  def with_lock(&block)
    File.open('/tmp/https-portal.lock', File::CREAT) do |lock|
      lock.flock File::LOCK_EX
      yield(block)
    end
  end
end
