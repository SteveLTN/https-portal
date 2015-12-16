module NAConfig
  def self.domains
    ENV.select{ |k| k.start_with? 'FORWARD_' }.map do |k,v|
      Domain.new(k.sub('FORWARD_', '').downcase, v)
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
end
