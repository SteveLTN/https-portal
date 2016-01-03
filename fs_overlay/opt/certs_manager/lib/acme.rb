module ACME
  def self.sign(domain)
    puts "Signing certificates from #{NAConfig.ca} ..."

    command = <<-EOC
      acme_tiny \
        --account-key /var/lib/https-portal/account.key \
        --csr #{domain.csr_path} \
        --acme-dir /var/www/challenges/ \
        --ca #{NAConfig.ca} > #{domain.signed_cert_path}
    EOC

    system(command)
  end
end
