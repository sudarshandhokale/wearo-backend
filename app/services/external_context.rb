module ExternalContext
  Result = Data.define(:city, :country_code, :weather)

  class InvalidDateRangeError < StandardError; end
end
