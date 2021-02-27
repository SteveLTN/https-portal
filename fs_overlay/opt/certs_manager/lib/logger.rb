module Logger
  def self.debug(str)
    if NAConfig.debug_mode?
      puts "[DEBUG] #{str}"
    end
  end
end
