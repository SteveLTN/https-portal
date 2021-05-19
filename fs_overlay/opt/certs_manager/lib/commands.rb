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

  def self.subnet_once
    response = RestClient.get(ENV['DAPPMANAGER_INTERNAL_IP'])
    return nil if response.code != 200 || response.to_str.length < 4

    ip_arr = response.to_str.split('.')
    ip_arr[3] = '0/24'

    ip_arr.join('.')
  rescue => e
    puts e
    nil
  end

  def self.subnet
    puts 'Trying to determine subnet your DAppNode is in..'
    30.times do
      subnet = subnet_once
      return subnet unless subnet.nil?

      puts '.'
      sleep 1
    end
    nil
  rescue
    puts 'An error occured during API call to DAPPMANAGER determine DAppNode subnet, local proxying is disabled'
    nil
  end

  def self.dappnode_domain_once
    response = RestClient.get(ENV['DAPPMANAGER_DOMAIN'])
    return response.to_str if response.code == 200

    nil
  rescue => e
    puts e
    nil
  end

  def get_dappnode_domain
    fulldomain_path = ENV['FULLDOMAIN_PATH'] 
    return File.read(fulldomain_path, encoding: 'utf-8') if File.exist?(fulldomain_path)

    puts 'Trying to determine DAppNode domain..'

    30.times do
      domain = dappnode_domain_once
      unless domain.nil?
        File.write(fulldomain_path, domain, encoding: 'utf-8')
        puts ' OK'
        return domain
      end
      puts '.'
      sleep 1
    end
    raise('Could not determine domain')
  rescue => e
    puts 'An error occured during API call to DAPPMANAGER determine DAppNode domain'
    puts e
    exit
  end
end
