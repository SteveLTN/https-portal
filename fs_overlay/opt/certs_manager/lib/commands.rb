require 'open-uri'

module Commands
  def download_intermediate_cert
    unless File.exist? intermediate_cert_path
      File.open(intermediate_cert_path, 'wb') do |saved_file|
        open('https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem', 'rb') do |read_file|
          saved_file.write(read_file.read)
        end
      end
    end
  end

  def chain_keys(domain)
    system "cat #{domain.signed_cert_path} #{intermediate_cert_path} > #{domain.chained_cert_path}"
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
