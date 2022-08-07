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
    Timeout.timeout(120) do
      puts "Signing certificates from #{domain.ca} ..."

      command = <<-EOC
        acme_tiny \
          --account-key #{NAConfig.portal_base_dir}/account.key \
          --csr #{domain.csr_path} \
          --acme-dir /var/www/default/challenges/ \
          --disable-check \
          --directory-url #{domain.ca} > #{domain.ongoing_cert_path}
      EOC

      raise FailedToSignException unless system(command)

      rename_ongoing_cert_and_key(domain)
    end
  rescue Exception => e
    puts <<-HERE
================================================================================
Failed to sign #{domain.name}.
Make sure your DNS is configured correctly and is propagated to this host
machine. Sometimes that takes a while.
================================================================================
    HERE

    raise e
  end

  def self.rename_ongoing_cert_and_key(domain)
    FileUtils.mv(domain.ongoing_cert_path, domain.signed_cert_path, force: true)
    FileUtils.mv(domain.ongoing_key_path, domain.key_path, force: true)
  end
end
