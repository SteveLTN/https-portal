module Nginx
  def self.config_http(domain)
    File.open("/etc/nginx/conf.d/#{domain.name}.conf" , 'w') do |f|
      f.write compiled_config(domain, false)
    end

    reload
  end

  def self.config_ssl(domain)
    File.open("/etc/nginx/conf.d/#{domain.name}.ssl.conf" , 'w') do |f|
      f.write compiled_config(domain, true)
    end

    reload
  end

  def self.start
    system 'nginx -q'
  end

  def self.reload
    system 'nginx -s reload'
  end

  private

  def self.compiled_config(domain, ssl)
    ERBBinding.new(domain, template_for(domain, ssl)).compile
  end

  def self.template_for(domain, ssl)
    ssl_ext = ssl ? '.ssl' : ''

    override = "/var/lib/nginx-conf/#{domain.name}#{ssl_ext}.conf"
    default = "/var/lib/nginx-conf/default#{ssl_ext}.conf"

    if File.exist? override
      File.read override
    else
      File.read default
    end
  end
end
