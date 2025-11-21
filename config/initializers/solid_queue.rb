if SolidQueue.respond_to?(:configure)
  SolidQueue.configure do |config|
    config.database = :primary
  end
end
