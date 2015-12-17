class Domain
  attr_accessor :name
  attr_accessor :proxy_target

  def initialize(name, proxy_target)
    @name = name
    @proxy_target = proxy_target
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
      "/var/lib/nginx-acme/#{name}"
    else
      "/var/lib/nginx-acme/#{name}-staging/"
    end
  end
end
