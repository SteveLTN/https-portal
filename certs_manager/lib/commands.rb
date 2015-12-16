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
end
