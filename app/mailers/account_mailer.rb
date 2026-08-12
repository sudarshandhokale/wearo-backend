class AccountMailer < ApplicationMailer
  def email_confirmation(user)
    @user = user
    @confirmation_url = frontend_url("/auth/confirm-email", AccountTokens.confirmation(user))
    mail(to: user.email, subject: I18n.t("account_mailer.email_confirmation.subject"))
  end

  def password_reset(user)
    @user = user
    @password_reset_url = frontend_url("/auth/reset-password", AccountTokens.password_reset(user))
    mail(to: user.email, subject: I18n.t("account_mailer.password_reset.subject"))
  end

  private

  def frontend_url(path, token)
    base_url = AppConfig.fetch(:frontend_url, default: "http://localhost:8081").to_s.chomp("/")
    "#{base_url}#{path}?#{URI.encode_www_form(token: token)}"
  end
end
