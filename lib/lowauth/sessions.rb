# frozen_string_literal: true

require 'digest'
require 'securerandom'

module LowAuth
  # Sessions in the sessions table. The browser keeps a random token in a cookie and the table keeps only its SHA-256,
  # so a leaked table can't log anyone in.
  module Sessions
    class << self
      # A new session's token, for the cookie.
      def create(user_id:, ip: nil, user_agent: nil)
        token = SecureRandom.urlsafe_base64(32)
        now = Time.now
        table.insert(token_digest: digest(token), user_id:, ip:, user_agent:, created_at: now,
                     expires_at: now + (LowAuth.session_days * 86_400))
        token
      end

      # The user a token's session belongs to, while it hasn't expired.
      def user(token)
        session = table.where(token_digest: digest(token)).where { expires_at > Time.now }.first
        return unless session

        LowAuth.users.where(id: session[:user_id]).first
      end

      def destroy(token)
        table.where(token_digest: digest(token)).delete
      end

      # Logs a user out everywhere, like after they change their password.
      def destroy_all(user_id:)
        table.where(user_id:).delete
      end

      private

      def table
        LowAuth.database[:sessions]
      end

      def digest(token)
        Digest::SHA256.hexdigest(token.to_s)
      end
    end
  end
end
