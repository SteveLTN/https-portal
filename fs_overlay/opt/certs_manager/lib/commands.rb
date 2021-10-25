require 'open-uri'
require 'fileutils'

module Commands
  def chain_certs(domain)
    # Keeping it for backward compatibility
    unless File.exist?(domain.chained_cert_path)
      FileUtils.ln_s(domain.signed_cert_path, domain.chained_cert_path)
    end
  end

  def mkdir(domain)
    system "mkdir -p #{domain.dir}"
  end

  def ensure_dockerhost_in_hosts
    unless File.foreach("/etc/hosts").grep(/dockerhost/).any?
      docker_host_ip = `/sbin/ip route|awk '/default/ { print $3 }'`.strip

      File.open('/etc/hosts', 'a') do |f|
        f.puts "#{docker_host_ip}\tdockerhost"
      end
    end
  end

  def generate_ht_access(domains)
    domains.each do |domain|
      if domain.basic_auth_enabled?
        system "htpasswd -bc #{domain.htaccess_path} #{domain.basic_auth_username} #{domain.basic_auth_password}"
      end
    end
  end

  def fail_and_shutdown
    Logger.debug ("Fail and Shutdown")
    Nginx.stop
    exit(1)
  end

  module_function :fail_and_shutdown
end
