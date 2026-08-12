module Visualization
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class InvalidInputError < Error; end
  class ProviderError < Error; end
end
