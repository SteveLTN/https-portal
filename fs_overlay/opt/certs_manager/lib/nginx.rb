require_relative './commands'

module Nginx
  class NginxReloadException < RuntimeError; end

  def self.setup
    compiled_basic_config = ERBBinding.new('/var/lib/nginx-conf/nginx.conf.erb', {}).compile

    File.open('/etc/nginx/nginx.conf', 'w') do |f|
      f.write compiled_basic_config
    end
  end

  def self.config_http(domain)
    File.open("/etc/nginx/conf.d/#{domain.name}.conf", 'w') do |f|
      f.write compiled_domain_config(domain, false)
    end
  end

  def self.config_ssl(domain)
    if domain.port == "443"
      file_path = "/etc/nginx/conf.d/#{domain.name}.ssl.conf" # Backwards compatibility
    else
      file_path = "/etc/nginx/conf.d/#{domain.name}_#{domain.port}.ssl.conf"
    end

    File.open(file_path, 'w') do |f|
      f.write compiled_domain_config(domain, true)
    end
  end

  def self.config_domain(domain)
    config_http(domain)
    config_ssl(domain)
  end

  def self.start(daemon = true)
    Logger.debug "Starting Nginx, daemon mode = #{daemon}"
    if daemon
      success = system 'nginx -q'
    else
      success = system 'nginx -q -g "daemon off;"'
    end

    unless success
      puts "Nginx failed to start, exiting ..."
      Commands.fail_and_shutdown
    end
  end

  def self.reload(kill_on_failure = false)
    Logger.debug "Reloading Nginx, kill_on_failure = #{kill_on_failure}"
    success = system 'nginx -s reload'

    if (!success && kill_on_failure)
      kill
    end

    success
  end

  def self.stop
    system 'nginx -s stop'
  end

  def self.kill
    system 'pkill -F /var/run/nginx.pid'
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
    ENV['ACME_CHALLENGE_BLOCK'] || <<-SNIPPET
      location /.well-known/acme-challenge/ {
          allow all;
          alias /var/www/default/challenges/;
          try_files $uri =404;
      }
    SNIPPET
  end
end
