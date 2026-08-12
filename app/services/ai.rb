module Ai
  class Error < StandardError; end
  class UsageLimitExceededError < Error; end

  class HttpError < Error
    attr_reader :status, :attempt_count

    def initialize(status: nil, attempt_count:)
      @status = status
      @attempt_count = attempt_count
      super("AI provider request failed")
    end
  end
end
