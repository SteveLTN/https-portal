TEST_DOMAIN = "test.nginx-acme.site"

require "open-uri"
require "openssl"

def cleanup_docker_machine
  `docker rm -f -v $(docker ps -qa)`
end

def read_https_content
  tries = 60
  open("https://#{TEST_DOMAIN}", ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE) do |f|
    f.read
  end
rescue Errno::ECONNREFUSED
  if (tries -= 1) > 0
    sleep 5
    retry
  end
end
