namespace :ai do
  namespace :evaluations do
    desc "Run deterministic outfit recommendation AI evaluation scenarios"
    task outfit_recommendations: :environment do
      summary = AiEvaluations::OutfitRecommendationRunner.call

      summary.results.each do |result|
        status = result.passed ? "PASS" : "FAIL"
        puts "[#{status}] #{result.id} - #{result.name}"

        if result.error.present?
          puts "  error: #{result.error}"
          next
        end

        result.checks.each do |check|
          check_status = check.passed ? "PASS" : "FAIL"
          puts "  [#{check_status}] #{check.name}: #{check.message}"
        end
      end

      puts "Result: #{summary.passed_count}/#{summary.total_count} scenarios passed"
      abort("AI evaluation failed") unless summary.passed?
    end
  end
end
