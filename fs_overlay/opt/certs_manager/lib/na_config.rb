module NAConfig
  def self.domains
    (env_domains + auto_discovered_domains).uniq(&:name)
  end

  def self.ca
    if production?
      'https://acme-v01.api.letsencrypt.org'
    else
      'https://acme-staging.api.letsencrypt.org'
    end
  end

  def self.production?
    ENV['PRODUCTION'] && ENV['PRODUCTION'].downcase == 'true'
  end

  def self.force_renew?
    ENV['FORCE_RENEW'] && ENV['FORCE_RENEW'].downcase == 'true'
  end

  def self.dhparam_path
    "/var/lib/https-portal/dhparam.pem"
  end

  def self.env_domains
    if ENV['DOMAINS']
      parse ENV['DOMAINS']
    else
      []
    end
  end

  def self.auto_discovered_domains
    if File.exist? "/var/run/domains"
      parse File.read("/var/run/domains")
    else
      []
    end
  end

  private

  def self.parse(domain_desc)
    domain_desc.split(',').map(&:strip).delete_if{ |s| s == "" }.map do |domain|
      name, upstream = domain.split('->').map(&:strip)
      Domain.new(name, upstream)
    end
  end
end
