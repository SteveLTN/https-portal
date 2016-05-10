require 'timeout'

module ACME
  def self.sign(domain)
    if domain.stage == 'local'
      OpenSSL.self_sign(domain)
    else
      le_sign(domain)
    end
  end

  private

  def self.le_sign(domain)
    Timeout::timeout(30) do

      puts "Signing certificates from #{domain.ca} ..."

      command = <<-EOC
        acme_tiny \
          --account-key /var/lib/https-portal/account.key \
          --no-verify \
          --csr #{domain.csr_path} \
          --acme-dir /var/www/default/challenges/ \
          --ca #{domain.ca} > #{domain.signed_cert_path}
      EOC

      system(command)

    end
  rescue
    puts <<-HERE
================================================================================
Failed to sign #{domain.name}, is DNS set up properly?
================================================================================
    HERE
  end
end
