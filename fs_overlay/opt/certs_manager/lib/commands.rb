require 'open-uri'
require 'rest-client'

module Commands
  def chain_certs(domain)
    # Keeping it for backward compatibility
    system "test ! -e #{domain.chained_cert_path} && ln -s #{domain.signed_cert_path} #{domain.chained_cert_path}"
  end

  def mkdir(domain)
    system "mkdir -p #{domain.dir}"
  end

  def add_dockerhost_to_hosts
    docker_host_ip = `/sbin/ip route|awk '/default/ { print $3 }'`.strip

    File.open('/etc/hosts', 'a') do |f|
      f.puts "#{docker_host_ip}\tdockerhost"
    end
  end

  def generate_ht_access(domains)
    domains.each do |domain|
      if domain.basic_auth_enabled?
        system "htpasswd -bc #{domain.htaccess_path} #{domain.basic_auth_username} #{domain.basic_auth_password}"
      end
    end
  end

  def ensure_dummy_certificate_for_default_server
    base_dir = File.join(NAConfig.portal_base_dir, "default_server")
    cert_path = File.join(NAConfig.portal_base_dir, "default_server/default_server.crt")
    key_path = File.join(NAConfig.portal_base_dir, "default_server/default_server.key")

    unless File.exist?(cert_path) && File.exist?(key_path)
      OpenSSL.generate_dummy_certificate(
        base_dir,
        cert_path,
        key_path
      )
    end
  end

  def get_dappnode_domain_once
    response = RestClient.get('http://my.dappnode/global-envs/DOMAIN')
    return response.to_str if response.code == 200

    nil
  rescue
    nil
  end

  def get_dappnode_domain
    for i in 1..30 do
      domain = get_dappnode_domain_once
      return domain unless domain.nil?

      sleep 1
    end
    raise('Could not determine domain')
  rescue
    puts 'An error occured during API call to DAPPMANAGER determine DAppNode domain'
    system 's6-svscanctl -t /var/run/s6/services'
    exit
  end
end
