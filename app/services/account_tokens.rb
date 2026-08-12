module AccountTokens
  CONFIRMATION_EXPIRATION = 2.days
  PASSWORD_RESET_EXPIRATION = 30.minutes

  class InvalidTokenError < StandardError; end

  class << self
    def confirmation(user)
      verifier.generate(
        { "user_id" => user.id, "email" => user.email },
        expires_in: CONFIRMATION_EXPIRATION,
        purpose: :email_confirmation
      )
    end

    def verify_confirmation(token)
      payload = verifier.verify(token, purpose: :email_confirmation)
      user = User.find(payload.fetch("user_id"))
      raise InvalidTokenError if user.confirmed?
      raise InvalidTokenError unless ActiveSupport::SecurityUtils.secure_compare(user.email, payload.fetch("email"))

      user
    rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound, KeyError
      raise InvalidTokenError
    end

    def password_reset(user)
      verifier.generate(
        { "user_id" => user.id, "password_fingerprint" => password_fingerprint(user) },
        expires_in: PASSWORD_RESET_EXPIRATION,
        purpose: :password_reset
      )
    end

    def verify_password_reset(token)
      payload = verifier.verify(token, purpose: :password_reset)
      user = User.find(payload.fetch("user_id"))
      expected = payload.fetch("password_fingerprint")
      raise InvalidTokenError unless ActiveSupport::SecurityUtils.secure_compare(password_fingerprint(user), expected)

      user
    rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound, KeyError
      raise InvalidTokenError
    end

    private

    def verifier
      Rails.application.message_verifier(:wearo_account_tokens)
    end

    def password_fingerprint(user)
      OpenSSL::Digest::SHA256.hexdigest(user.encrypted_password)
    end
  end
end
