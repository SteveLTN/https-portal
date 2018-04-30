require 'open-uri'

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

  def intermediate_cert_path
    '/var/lib/https-portal/intermediate.pem'
  end
end
