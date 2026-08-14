module AiEvaluations
  CheckResult = Data.define(:name, :passed, :message, :details)
  ScenarioResult = Data.define(:id, :name, :passed, :checks, :recommended_outfits, :error) do
    def failed_checks
      checks.reject(&:passed)
    end
  end
  Summary = Data.define(:results) do
    def passed?
      results.all?(&:passed)
    end

    def total_count
      results.length
    end

    def passed_count
      results.count(&:passed)
    end

    def failed_count
      total_count - passed_count
    end
  end
end
