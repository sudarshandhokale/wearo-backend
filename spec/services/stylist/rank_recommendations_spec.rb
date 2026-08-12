require "rails_helper"

RSpec.describe Stylist::RankRecommendations do
  let(:item) { build_stubbed(:clothing_item) }
  let(:candidates) do
    4.times.map do |index|
      Stylist::ScoredCombination.new(
        items: { "top" => item },
        score: 90 - index,
        score_breakdown: { "color" => 90 }
      )
    end
  end

  it "uses only valid unique provider candidate ids" do
    provider = instance_double(Stylist::Providers::Openai)
    allow(provider).to receive(:call).and_return(
      rankings: [
        { "candidate_id" => 2, "explanation" => "Best contextual match." },
        { "candidate_id" => 2, "explanation" => "Duplicate." },
        { "candidate_id" => 99, "explanation" => "Unknown." }
      ],
      metadata: { "provider" => "test" }
    )

    result = described_class.call(scored_combinations: candidates, prompt: "Dinner", context: { "occasion" => "dinner" }, provider: provider)

    expect(result.length).to eq(3)
    expect(result.first.score).to eq(89)
    expect(result.first.explanation).to eq("Best contextual match.")
  end

  it "falls back to deterministic ranking when the provider is unavailable" do
    provider = instance_double(Stylist::Providers::Openai)
    allow(provider).to receive(:call).and_raise(Stylist::ProviderError)

    result = described_class.call(scored_combinations: candidates, prompt: "Dinner", context: { "occasion" => "dinner" }, provider: provider)

    expect(result.map(&:score)).to eq([ 90, 89, 88 ])
    expect(result.first.ranking_metadata).to eq("provider" => "deterministic")
  end
end
