require 'timeout'

module ACME
  def self.sign(domain)
    Timeout::timeout(30) do

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
  rescue Timeout::Error => e
    puts 'Signing certificates timed out. Is DNS set up properly?'
  end
end
