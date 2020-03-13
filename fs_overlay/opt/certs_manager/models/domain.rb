require 'fileutils'

class Domain
  STAGES = %w(production staging local).freeze

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
    "/var/lib/https-portal/#{name}/#{stage}/"
  end

  def www_root
    "/var/www/vhosts/#{name}"
  end

  def ensure_welcome_page
    return if upstream || redirect_target_url

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
    when 'staging'
      'https://acme-staging-v02.api.letsencrypt.org/directory'
    end
  end

  def name
    parsed_descriptor[:domain]
  end

  def upstream
    parsed_descriptor[:upstream] if parsed_descriptor[:mode] == '->'
  end

  def redirect_target_url
    return unless parsed_descriptor[:mode] == '=>'

    url = parsed_descriptor[:upstream]

    if url.start_with? "http"
      return url
    else
      return "https://" + url
    end
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
    puts "DEBUG: name:'#{name}' upstream:'#{upstream}' redirect_target:'#{redirect_target_url}'"
  end

  private

  def create_dir
    FileUtils.mkdir_p dir
  end

  def parsed_descriptor
    if defined? @parsed_descriptor
      @parsed_descriptor
    else
      regex = /^(?:\[(?<ips>[0-9.:\/, ]*)\]\s*)?(?:(?<user>[^:@\[\]]+)(?::(?<pass>[^@]*))?@)?(?<domain>[a-z0-9._\-]+?)(?:(?:\s*(?<mode>[-=]>)\s*(?<upstream>[a-z0-9.:\/_\-]+))?\s*(:?#(?<stage>[a-z]*))?)?$/i
      match = descriptor.strip.match(regex)
      if match.nil?
        STDERR.puts "Error: Invalid descriptor #{descriptor}"
        @parsed_descriptor = nil
      else
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
