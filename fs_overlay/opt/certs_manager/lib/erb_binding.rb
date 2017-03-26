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

  def initialize(template_path, **binding_hash)
    @template = File.read(template_path)
    @binding_hash = binding_hash
  end

  def compile
    clean_binding = CleanBinding.new(@binding_hash)

    ERB.new(@template).result(clean_binding.get)
  end
end
