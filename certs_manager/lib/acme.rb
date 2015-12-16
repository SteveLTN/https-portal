module ACME
  def self.sign(domain)
    command = <<-EOC
      acme_tiny.py \
        --account-key /var/lib/nginx-acme/account.key \
        --csr #{domain.csr_path} \
        --acme-dir /var/www/challenges/ \
        --ca #{NAConfig.ca} > #{domain.signed_cert_path}
    EOC

    system command
  end
end
