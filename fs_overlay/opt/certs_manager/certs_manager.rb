Dir[File.dirname(__FILE__) + '/lib/*.rb'].each { |file| require file }
require_relative 'models/domain'
require 'fileutils'

class CertsManager
  include Commands

  attr_accessor :lock

  def setup
    setup_config(true)
  end

  def reconfig
    setup_config(false)
  end

  def setup_config(initial)
    with_lock do
      ensure_dockerhost_in_hosts
      ensure_crontab

      NAConfig.domains.each do |domain|
        if NAConfig.debug_mode?
          domain.print_debug_info
        end
        domain.ensure_welcome_page
      end

      ensure_dummy_certificate_for_default_server
      OpenSSL.ensure_dhparam
      OpenSSL.ensure_account_key

      generate_ht_access(NAConfig.domains)

      ensure_keys_and_certs_exist(NAConfig.domains)
      config_domains(NAConfig.domains)
      Nginx.setup

      if initial
        Nginx.start
      else
        Nginx.reload
      end

      ensure_signed(NAConfig.domains, true)

      if initial
        Nginx.stop
      else
        Nginx.reload
      end
    end
    if initial
      sleep 1 # Give Nginx some time to shutdown
    end
  end

  def renew
    puts "Renewing ..."
    NAConfig.domains.each(&:print_debug_info) if NAConfig.debug_mode?
    with_lock do
      NAConfig.domains.each do |domain|
        if NAConfig.debug_mode?
          domain.print_debug_info
        end

        if OpenSSL.need_to_sign_or_renew? domain
          ACME.sign(domain)
          chain_certs(domain)
          Nginx.reload
          puts "Renewed certs for #{domain.name}"
        else
          puts "Renewal skipped for #{domain.name}, it expires at #{OpenSSL.expires_in_days(domain.signed_cert_path)} days from now."
        end
      end
    end
    puts "Renewal done."
  end

  private

  def config_domains(domains)
    Dir['/etc/nginx/conf.d/*.conf'].each { |file| File.delete file }
    domains.each do |domain|
      Nginx.config_domain(domain)
    end
  end

  def ensure_keys_and_certs_exist(domains)
    # Just to make sure there is some sort of certificate existing,
    # whether being dummy or real,
    # so Nginx can start
    dummy_cert_path = File.join(NAConfig.portal_base_dir, "default_server/default_server.crt")
    dummy_key_path = File.join(NAConfig.portal_base_dir, "default_server/default_server.key")

    domains.each do |domain|
      mkdir(domain)

      if NAConfig.force_renew? || !OpenSSL.key_and_cert_exist?(domain)
        Logger.debug "copying dummy key and cert for #{domain.name}"
        FileUtils.cp(dummy_key_path, domain.key_path)
        FileUtils.cp(dummy_cert_path, domain.signed_cert_path)
        chain_certs(domain)
      end
    end
  end

  def ensure_signed(domains, exit_on_failure = false)
    Logger.debug ("ensure_signed")
    domains.each do |domain|
      if OpenSSL.need_to_sign_or_renew? domain
        mkdir(domain)
        OpenSSL.create_domain_key(domain)
        OpenSSL.create_csr(domain)
        if ACME.sign(domain)
          chain_certs(domain)
          Nginx.reload || exit(1)
          puts "Signed certificate for #{domain.name}"
        else
          puts("Failed to obtain certs for #{domain.name}")
          exit(1) if exit_on_failure
        end
      else
        puts "Signing skipped for #{domain.name}, it expires at #{OpenSSL.expires_in_days(domain.signed_cert_path)} days from now."
      end
    end
  end

  def with_lock(&block)
    File.open('/tmp/https-portal.lock', File::CREAT) do |lock|
      lock.flock File::LOCK_EX
      yield(block)
    end
  end

  def ensure_crontab
    crontab = '/etc/crontab'

    unless File.exist?(crontab)
      File.open(crontab, 'w') do |file|
        file.write compiled_crontab
      end
    end
  end

  def compiled_crontab
    ERBBinding.new('/var/lib/crontab.erb', {}).compile
  end
end
