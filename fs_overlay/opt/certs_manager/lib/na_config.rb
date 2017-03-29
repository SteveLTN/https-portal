module NAConfig
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
    '/var/lib/https-portal/dhparam.pem'
  end

  def self.env_domains
    if ENV['DOMAINS']
      parse ENV['DOMAINS']
    else
      []
    end
  end

  def self.auto_discovered_domains
    if File.exist? '/var/run/domains'
      parse File.read('/var/run/domains')
    else
      []
    end
  end

  private

  def self.parse(domain_desc)
    domain_desc.split(',').map(&:strip).delete_if { |s| s == '' }.map do |descriptor|
      Domain.new(descriptor)
    end
  end
end
