module External
  class Error < StandardError; end
  class InvalidRequestError < Error; end
  class ProviderError < Error; end
end
