require 'timeout'
require 'fileutils'

module ACME
  class FailedToSignException < RuntimeError; end

  def self.sign(domain)
    if domain.stage == 'local'
      OpenSSL.self_sign(domain)
    else
      le_sign(domain)
    end
  rescue FailedToSignException, Timeout::Error => e
    false
  end

  private

  def self.le_sign(domain)
    Timeout.timeout(30) do
      puts "Signing certificates from #{domain.ca} ..."

      command = <<-EOC
        acme_tiny \
          --account-key /var/lib/https-portal/account.key \
          --csr #{domain.csr_path} \
          --acme-dir /var/www/default/challenges/ \
          --ca #{domain.ca} > #{domain.ongoing_cert_path}
      EOC

      raise FailedToSignException unless system(command)

      rename_ongoing_cert(domain)
    end
  rescue Exception => e
    puts <<-HERE
================================================================================
Failed to sign #{domain.name}, is DNS set up properly?
================================================================================
    HERE

    raise e
  end

  def self.rename_ongoing_cert(domain)
    FileUtils.mv(domain.ongoing_cert_path, domain.signed_cert_path, force: true)
  end
end
