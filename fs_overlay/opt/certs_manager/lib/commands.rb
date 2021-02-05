require 'open-uri'
require 'rest-client'
require_relative 'nginx'

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

  def generate_dummy_certificate_for_default_server
    OpenSSL.generate_dummy_certificate(
      File.join(NAConfig.portal_base_dir, "default_server"),
      File.join(NAConfig.portal_base_dir, "default_server/default_server.crt"),
      File.join(NAConfig.portal_base_dir, "default_server/default_server.key")
    )
  end

  def get_dappnode_domain
    for i in 1..20 do
      response = RestClient.get('http://my.dappnode/global-envs/DOMAIN')
      return response.to_str if response.code == 200

      sleep 1
    end
    raise('Could not determine domain')
  rescue => e
    puts "An error occured during API call to DAPPMANAGER determine DAppnode domain"
    puts e
    Nginx.stop
    exit
  end
end
