Devise.setup do |config|
  require "devise/orm/active_record"

  config.mailer_sender = AppConfig.fetch(:mailer_from, default: "no-reply@wearo.app")
  config.case_insensitive_keys = [ :email ]
  config.strip_whitespace_keys = [ :email ]
  config.skip_session_storage = [ :http_auth, :params_auth ]
  config.stretches = Rails.env.test? ? 1 : 12
  config.password_length = 8..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  config.reconfirmable = false
  config.expire_all_remember_me_on_sign_out = true
  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other
end
