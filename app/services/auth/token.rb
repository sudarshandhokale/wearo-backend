module Auth
  class Token
    ALGORITHM = "HS256"
    EXPIRATION = 1.day

    DecodeError = Class.new(StandardError)
    RevokedTokenError = Class.new(StandardError)

    class << self
      def encode(user, expires_at: EXPIRATION.from_now)
        payload = {
          sub: user.id,
          jti: SecureRandom.uuid,
          iss: "wearo",
          exp: expires_at.to_i
        }

        JWT.encode(payload, secret, ALGORITHM)
      end

      def decode(token)
        payload = JWT.decode(token, secret, true, algorithm: ALGORITHM).first.with_indifferent_access
        raise RevokedTokenError if JwtDenylist.revoked?(payload[:jti])

        payload
      rescue JWT::DecodeError => e
        raise DecodeError, e.message
      end

      def revoke(token)
        payload = JWT.decode(token, secret, true, algorithm: ALGORITHM).first.with_indifferent_access
        JwtDenylist.find_or_create_by!(jti: payload[:jti]) do |record|
          record.exp = Time.zone.at(payload[:exp])
        end
      rescue JWT::DecodeError
        nil
      end

      private

      def secret
        AppConfig.fetch(:devise_jwt_secret_key, default: Rails.application.secret_key_base)
      end
    end
  end
end
