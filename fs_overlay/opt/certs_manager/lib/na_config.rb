module NAConfig
  def self.portal_base_dir
    "/var/lib/https-portal"
  end

  def self.domains
    (env_domains + auto_discovered_domains).uniq(&:name)
  end

  def self.stage
    if ENV['STAGE']
      ENV['STAGE']
    else # legacy
      if production_key?
        'production'
      else
        'staging'
      end
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
    if File.exist? '/var/run/domains.d/domains'
      parse File.read('/var/run/domains.d/domains')
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
