module ACME
  def self.sign(domain)
    command = <<-EOC
      acme_tiny \
        --account-key /var/lib/nginx-acme/account.key \
        --csr #{domain.csr_path} \
        --acme-dir /var/www/challenges/ \
        --ca #{NAConfig.ca} > #{domain.signed_cert_path}
    EOC

    unless system(command)
      puts("Failed to obtain certs for #{domain.name}")
      exit(1)
    end
  end
end
