require_relative 'lib/acme'
require_relative 'lib/commands'
require_relative 'lib/nginx'

class CertsManager
  def entrypoint
    Commands.gen_keys
    Commands.create_csr
    Nginx.start
    Nginx.config_http

    ACME.sign

    Commands.download_intermediate_cert
    Commands.cat_keys
    Nginx.config_ssl
    Commands.start_cron

    sleep
  end

  def renew
    ACME.sign
    Commands.download_intermediate_cert
    Commands.cat_keys
    Nginx.reload
  end
end
