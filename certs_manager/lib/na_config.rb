module NAConfig
  def self.domains
    ENV.select{ |k| k.start_with? 'NGINX-ACME_' }.map do |k,v|
      Domain.new(k.sub('NGINX-ACME_', '').downcase, v)
    end
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
    "/var/lib/nginx-acme/dhparam.pem"
  end
end
