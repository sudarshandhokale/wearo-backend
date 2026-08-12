class ApplicationMailer < ActionMailer::Base
  default from: -> { AppConfig.fetch(:mailer_from, default: "no-reply@wearo.app") }
  layout "mailer"
end
