require_relative 'commands'

module NAConfig
  extend Commands

  def self.portal_base_dir
    "/var/lib/https-portal"
  end

  def self.domains
    (env_domains + auto_discovered_domains).uniq(&:name)
  end

  def self.stage
    if ENV['PUBLIC_DOMAIN']
      ENV['STAGE']
    elsif get_dappnode_domain.include? 'dyndns.dappnode.io'
      'dappnode-api'
    else
      'production'
    end
  end

  def self.production_key?
    ENV['PRODUCTION'] && ENV['PRODUCTION'].casecmp('true').zero?
  end

  def self.force_renew?
    ENV['FORCE_RENEW'] && ENV['FORCE_RENEW'].casecmp('true').zero?
  end

  def self.dhparam_path
    "#{NAConfig.portal_base_dir}/dhparam.pem"
  end

  def self.env_domains
    if ENV['DOMAINS']
      parse ENV['DOMAINS']
    else
      []
    end
  end

  def self.auto_discovered_domains
    file_name = File.join(ENV['DOMAINS_DIR'], 'domains')
    if File.exist? file_name
      parse File.read(file_name)
    else
      []
    end
  end

  def self.debug_mode?
    ENV['DEBUG']
  end

  def self.renew_margin_days
    ENV['RENEW_MARGIN_DAYS'].to_i != 0 ? ENV['RENEW_MARGIN_DAYS'].to_i : 30
  end

  def self.key_length
    ENV['NUMBITS'] =~ /^[0-9]+$/ ? ENV['NUMBITS'] : 2048
  end

  private

  def self.parse(domain_desc)
    domain_desc.split(',').map(&:strip).delete_if { |s| s == '' }.map do |descriptor|
      Domain.new(descriptor)
    end
  end
end
