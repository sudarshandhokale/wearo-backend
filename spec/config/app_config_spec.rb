require "rails_helper"

RSpec.describe AppConfig do
  around do |example|
    original = ENV.fetch("OPENAI_API_KEY", nil)
    example.run
  ensure
    original.nil? ? ENV.delete("OPENAI_API_KEY") : ENV["OPENAI_API_KEY"] = original
  end

  it "falls back to credentials when the environment value is blank" do
    ENV["OPENAI_API_KEY"] = ""
    allow(Rails.application.credentials).to receive(:dig).with(:app_config, :openai_api_key).and_return("credential-key")

    expect(described_class.fetch(:openai_api_key)).to eq("credential-key")
  end

  it "keeps present environment values before credentials" do
    ENV["OPENAI_API_KEY"] = "env-key"
    allow(Rails.application.credentials).to receive(:dig).with(:app_config, :openai_api_key).and_return("credential-key")

    expect(described_class.fetch(:openai_api_key)).to eq("env-key")
  end
end
