module Nginx
  def self.setup
    compiled_basic_config = ERBBinding.new('/var/lib/nginx-conf/nginx.conf.erb').compile

    File.open('/etc/nginx/nginx.conf', 'w') do |f|
      f.write compiled_basic_config
    end
  end

  def self.config_http(domain)
    File.open("/etc/nginx/conf.d/#{domain.name}.conf", 'w') do |f|
      f.write compiled_domain_config(domain, false)
    end

    reload
  end

  def self.config_ssl(domain)
    File.open("/etc/nginx/conf.d/#{domain.name}.ssl.conf", 'w') do |f|
      f.write compiled_domain_config(domain, true)
    end

    reload
  end

  def self.start
    system 'nginx -q'
  end

  def self.reload
    system 'nginx -s reload'
  end

  def self.stop
    system 'nginx -s stop'
  end

  private

  def self.compiled_domain_config(domain, ssl)
    binding_hash = {
      domain: domain,
      acme_challenge_location: acme_challenge_location_snippet,
      dhparam_path: NAConfig.dhparam_path
    }

    ERBBinding.new(template_path(domain, ssl), binding_hash).compile
  end

  def self.template_path(domain, ssl)
    ssl_ext = ssl ? '.ssl' : ''

    override = "/var/lib/nginx-conf/#{domain.name}#{ssl_ext}.conf.erb"
    default = "/var/lib/nginx-conf/default#{ssl_ext}.conf.erb"

    if File.exist? override
      override
    else
      default
    end
  end

  def self.acme_challenge_location_snippet
    <<-SNIPPET
      location /.well-known/acme-challenge/ {
          alias /var/www/default/challenges/;
          try_files $uri =404;
      }
    SNIPPET
  end
end
