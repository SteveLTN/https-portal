class Domain
  attr_accessor :name
  attr_accessor :upstream

  def initialize(name, upstream)
    @name = name
    @upstream = upstream
  end

  def csr_path
    File.join(dir, 'domain.csr')
  end

  def signed_cert_path
    File.join(dir, 'signed.crt')
  end

  def chained_cert_path
    File.join(dir, 'chained.pem')
  end

  def key_path
    File.join(dir, 'domain.key')
  end

  def dir
    if NAConfig.production?
      "/var/lib/https-portal/#{name}"
    else
      "/var/lib/https-portal/#{name}-staging/"
    end
  end
end
