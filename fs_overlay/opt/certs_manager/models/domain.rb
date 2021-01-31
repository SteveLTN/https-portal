require 'fileutils'
require 'rest-client'

class Domain
  STAGES = %w(production staging local dappnode-api).freeze

  attr_reader :descriptor

  def initialize(descriptor)
    @descriptor = descriptor

    create_dir
  end

  def csr_path
    File.join(dir, 'domain.csr')
  end

  def signed_cert_path
    File.join(dir, 'signed.crt')
  end

  # For backward compatibility
  def chained_cert_path
    File.join(dir, 'chained.crt')
  end

  def ongoing_cert_path
    File.join(dir, 'signed.ongoing.crt')
  end

  def key_path
    File.join(dir, 'domain.key')
  end

  def htaccess_path
    File.join(dir, 'htaccess')
  end

  def dir
    return File.join(NAConfig.portal_base_dir, 'wildcard_certs/') if ENV['STAGE'] == 'dappnode-api'

    File.join(NAConfig.portal_base_dir, name, stage)
  end

  def www_root
    File.join("/var/www/vhosts/", name)
  end

  def ensure_welcome_page
    return if upstreams.length > 0 || redirect_target_url

    index_html = File.join(www_root, 'index.html')

    unless File.exist?(index_html)
      FileUtils.mkdir_p www_root

      File.open(index_html, 'w') do |file|
        file.write compiled_welcome_page
      end
    end
  end

  def ca
    case stage
    when 'production'
      'https://acme-v02.api.letsencrypt.org/directory'
    when 'local'
      nil
    when 'dappnode-api'
      nil
    when 'staging'
      'https://acme-staging-v02.api.letsencrypt.org/directory'
    end
  end

  def name
    parsed_descriptor[:domain]
  end

  def global
      if ENV['PUBLIC_DOMAIN']
        ENV['PUBLIC_DOMAIN']
      else
        for i in 1..20 do
          response = RestClient.get('http://my.dappnode/global-envs/DOMAIN')
          return response.to_str if response.code == 200

          sleep 1
        end
        raise('Could not determine domain')
      end
  end

  def upstream_backend_name
    "backend_" + parsed_descriptor[:domain]
  end

  def upstream_proto
    mode = parsed_descriptor[:mode]
    return unless ["->", "=>"].include? mode

    default = mode == "->" ? "http://" : "https://"
    parsed_descriptor[:upstream_proto] || default
  end

  def upstreams
    upstreams = parsed_descriptor[:upstreams].to_s.split("|").delete_if { |v| v.empty? }
    upstreams.map do |v|
      match = v.match(/^(?<address>[^\[]+)(?:\[(?<parameters>.*)\])?$/)
      raise "Invalid upstream: #{v}" unless match

      match.named_captures.transform_keys(&:to_sym)
    end
  end

  def multiple_upstreams?
    upstreams.length > 1
  end

  def upstream
    # For backward compatibility it is important to return nil for static site and redirect mode
    return unless parsed_descriptor[:mode] == '->'

    upstream = upstreams.first
    return if upstream.nil?

    return upstream_proto + upstream[:address]
  end

  def redirect_target_url
    return unless parsed_descriptor[:mode] == '=>'

    upstream = upstreams.first
    return if upstream.nil?

    raise "Parameters not supported on redirect-target" unless upstream[:parameters].nil?

    upstream_proto + upstream[:address]
  end

  def stage
    val = parsed_descriptor[:stage].to_s.empty? ? NAConfig.stage : parsed_descriptor[:stage]
    
    if STAGES.include?(val)
      val
    else
      STDERR.puts "Error: Invalid stage #{val}"
      nil
    end
  end

  def basic_auth_username
    parsed_descriptor[:user]
  end

  def basic_auth_password
    parsed_descriptor[:pass]
  end

  def basic_auth_enabled?
    basic_auth_username && basic_auth_password
  end

  def access_restriction
    if defined? @access_restriction
      @access_restriction
    else
      if parsed_descriptor[:ips].nil?
        @access_restriction = nil
      else
        @access_restriction = parsed_descriptor[:ips].split(' ')
      end
    end
  end

  def print_debug_info
    puts "----------- BEGIN DOMAIN CONFIG -------------"
    puts "name: #{name}"
    puts "stage: #{stage}"
    puts "upstream: #{upstream}"
    puts "upstreams: #{upstreams.inspect}"
    puts "upstream_proto: #{upstream_proto}"
    puts "redirect_target_url: #{redirect_target_url}"
    puts "basic_auth_username: #{basic_auth_username}"
    puts "basic_auth_password: #{basic_auth_password}"
    puts "access_restriction: #{access_restriction}"
    puts "-------- --- END DOMAIN CONFIG  -------------"
  end

  private

  def create_dir
    FileUtils.mkdir_p dir
  end

  def parsed_descriptor
    if defined? @parsed_descriptor
      @parsed_descriptor
    else
      regex = %r{
        ^
        (?:\[(?<ips>[0-9.:\/, ]*)\]\s*)?
        (?:(?<user>[^:@\[\]]+)(?::(?<pass>[^@]*))?@)?(?<domain>[a-z0-9._\-]+?)
        (?:
          \s*(?<mode>[-=]>)\s*
          (?<upstream_proto>https?:\/\/)?
          (?<upstreams>[a-z0-9.:\/_|\[= \]\-]+?)
        )?
        (:?\s+\#(?<stage>[a-z]*))?
        $
      }xi

      match = descriptor.strip.match(regex)
      if match.nil?
        STDERR.puts "Error: Invalid descriptor #{descriptor}"
        @parsed_descriptor = nil
      else
        match = match.named_captures.transform_keys(&:to_sym)

        @parsed_descriptor = match
      end
    end
  end

  def compiled_welcome_page
    binding_hash = {
      domain: self,
      NAConfig: NAConfig
    }

    ERBBinding.new('/var/www/default/index.html.erb', binding_hash).compile
  end
end
