require 'open-uri'
require 'openssl'

module PortalHelpers
  def docker_compose(command, env: {})
    case command.to_sym
    when :up
      command = 'up -d'
    end

    system(env, "docker-compose --project-name portalspec #{command}")
  end

  def read_https_content(path = nil)
    tries = 60
    open("https://#{ENV['TEST_DOMAIN']}/#{path}", ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE) do |f|
      f.read
    end
  rescue Errno::ECONNREFUSED
    if (tries -= 1) > 0
      sleep 10
      retry
    end
  end
end
