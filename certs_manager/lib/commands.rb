require 'open-uri'

module Commands
  def download_intermediate_cert
    File.open('/var/lib/nginx-acme/intermediate.pem', 'wb') do |saved_file|
      open('https://letsencrypt.org/certs/lets-encrypt-x1-cross-signed.pem', "rb") do |read_file|
        saved_file.write(read_file.read)
      end
    end
  end

  def chain_keys(domain)
    system "cat #{domain.signed_cert_path} /var/lib/nginx-acme/intermediate.pem > #{domain.chained_cert_path}"
  end

  def start_cron
    system 'cron'
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

  def start_docker_gen
    if File.socket? "/var/run/docker.sock"
      system "docker-gen -watch -only-exposed -notify reconfig /etc/docker-gen/domains.tmpl /var/run/domains &"
    end
  end
end
