require 'fileutils'

class Domain
  STAGES = %w(production staging local).freeze

  attr_reader :descriptor

  def initialize(descriptor)
    @descriptor = descriptor
  end

  def csr_path
    File.join(dir, 'domain.csr')
  end

  def signed_cert_path
    File.join(dir, 'signed.crt')
  end

  # For backward compatibility
  def chained_cert_path
    puts "Warning: `chained_cert_path` is deprecated. Use `signed_cert_path` instead in your Nginx config file."

    signed_cert_path
  end

  def ongoing_cert_path
    File.join(dir, 'signed.ongoing.crt')
  end

  def key_path
    File.join(dir, 'domain.key')
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
    if @name
      @name
    else
      @name = descriptor.split('->').first.split(' ').first.strip
    end
  end

  def upstream
    if @upstream
      @upstream
    else
      match = descriptor.match(/->\s*([^#\s][\S]*)/)
      @upstream = match[1] if match
    end
  end

  def redirect_target_url
    if @redirect_target_url
      @redirect_target_url
    else
      match = descriptor.match(/=>\s*([^#\s][\S]*)/)
      @redirect_target_url = match[1] if match
    end
  end

  def stage
    if @stage
      @stage
    else
      match = descriptor.match(/\s#(\S+)$/)

      @stage = if match
                 match[1]
               else
                 NAConfig.stage
               end

      if STAGES.include?(@stage)
        @stage
      else
        puts "Error: Invalid stage #{@stage}"
        nil
      end
    end
  end

  private

  def compiled_welcome_page
    binding_hash = {
      domain: self,
      NAConfig: NAConfig
    }

    ERBBinding.new('/var/www/default/index.html.erb', binding_hash).compile
  end
end
