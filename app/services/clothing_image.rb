module ClothingImage
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class InvalidInputError < Error; end
  class ProviderError < Error; end

  def self.auto_polish_enabled?
    ActiveModel::Type::Boolean.new.cast(AppConfig.fetch(:clothing_image_auto_polish_enabled, default: true))
  end
end
