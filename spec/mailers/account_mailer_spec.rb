require "rails_helper"

RSpec.describe AccountMailer do
  let(:user) { create(:user, first_name: "Maya", email: "maya@example.com") }

  it "sends a frontend email confirmation link" do
    allow(AppConfig).to receive(:fetch).and_call_original
    allow(AppConfig).to receive(:fetch).with(:frontend_url, default: "http://localhost:8081").and_return("https://app.wearo.test")

    mail = described_class.email_confirmation(user)

    expect(mail.to).to eq([ "maya@example.com" ])
    expect(mail.subject).to eq(I18n.t("account_mailer.email_confirmation.subject"))
    expect(mail.body.encoded).to include("https://app.wearo.test/auth/confirm-email?token=")
  end
end
