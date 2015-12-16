class Domain
  attr_accessor :name
  attr_accessor :proxy_target

  def initialize(name, proxy_target)
    @name = name
    @proxy_target = proxy_target
  end

  def csr_path
    "#{dir}/domain.csr"
  end

  def signed_cert_path
    "#{dir}/signed.crt"
  end

  def chained_cert_path
    "#{dir}/chained.pem"
  end

  def key_path
    "#{dir}/domain.key"
  end

  def dir
    "/var/lib/nginx-acme/#{name}"
  end
end
