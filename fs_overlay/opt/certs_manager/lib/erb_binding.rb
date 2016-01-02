require 'erb'

class ERBBinding

  class CleanBinding
    def initialize(hash)
      hash.each do |key, value|
        singleton_class.send(:define_method, key) { value }
      end
    end

    def get
      binding
    end
  end

  def initialize(domain, template)
    @domain = domain
    @template = template
  end

  def compile
    fake_binding = CleanBinding.new(
      domain: @domain,
      acme_challenge_location: acme_challenge_location_snippet,
      dhparam_path: NAConfig.dhparam_path
    )

    ERB.new(@template).result(fake_binding.get)
  end

  private

  def acme_challenge_location_snippet
    <<-SNIPPET
      location /.well-known/acme-challenge/ {
          alias /var/www/challenges/;
          try_files $uri =404;
      }
    SNIPPET
  end

end
