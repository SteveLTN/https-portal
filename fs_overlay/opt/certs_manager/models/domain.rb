require 'fileutils'

class Domain
  STAGES = ['production', 'staging', 'local']

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

  def ongoing_cert_path
    File.join(dir, 'signed.ongoing.crt')
  end

  def chained_cert_path
    File.join(dir, 'chained.pem')
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
    return if upstream

    index_html = File.join(www_root, 'index.html')

    unless File.exists?(index_html)
      FileUtils.mkdir_p www_root

      File.open(index_html, 'w') do |file|
        file.write compiled_welcome_page
      end
    end
  end

  def ca
    case stage
    when 'production'
      'https://acme-v01.api.letsencrypt.org'
    when 'local'
      nil
    when 'staging'
      'https://acme-staging.api.letsencrypt.org'
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

  def stage
    if @stage
      @stage
    else
      match = descriptor.match(/\s#(\S+)$/)

      if match
        @stage = match[1]
      else
        @stage = NAConfig.stage
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
