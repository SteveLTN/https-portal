module Nginx
  def self.config_http
    system('cp /root/nginx-conf/nginx-acme.steveltn.me.conf /etc/nginx/conf.d/') && reload
  end

  def self.config_ssl
    system('cp /root/nginx-conf/nginx-acme.steveltn.me.ssl.conf /etc/nginx/conf.d/') && reload
  end

  def self.start
    system 'nginx -q'
  end

  def self.reload
    system 'nginx -s reload'
  end
end
