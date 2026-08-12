module ClothingAnalysis
  AnalysisResult = Data.define(:attributes, :metadata)

  class Error < StandardError; end
  class ConfigurationError < Error; end
  class InvalidResultError < Error; end
  class ProviderError < Error; end
end
