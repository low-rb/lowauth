# frozen_string_literal: true

require 'digest'
require 'securerandom'

module LowAuth
  # Links that let a user set their password, which the app emails them: to reset one they've forgotten, or to choose
  # one when they're invited. Like a session, a link holds a random token and the password_links table keeps only its
  # SHA-256. A link works once, until it expires, and a new one replaces any the user had.
  module PasswordLinks
    # A user asking again within this many seconds gets no new link, so nobody can flood someone's inbox.
    REQUEST_INTERVAL = 5 * 60

    class << self
      # A new link's token for a user. It lasts an hour, or longer for an invite, like hours: 7 * 24.
      def create(user_id:, hours: 1)
        token = SecureRandom.urlsafe_base64(32)
        now = Time.now
        LowAuth.database.transaction do
          table.where(user_id:).delete
          table.insert(token_digest: digest(token), user_id:, created_at: now, expires_at: now + (hours * 3600))
        end
        token
      end

      # The user who asked for a link by their login, like a username or email, and the link's token, or nil when
      # there's no such user, they can't log in, or they asked within the last five minutes.
      def request(login)
        user = LowAuth.find_user(login)
        return unless user && LowAuth.can_login.call(user)
        return if table.where(user_id: user[:id]).where { created_at > Time.now - REQUEST_INTERVAL }.any?

        [user, create(user_id: user[:id])]
      end

      # The user a link is for, while it's unused and hasn't expired.
      def user(token)
        link = table.where(token_digest: digest(token)).where { expires_at > Time.now }.first
        return unless link

        user = LowAuth.users.where(id: link[:user_id]).first
        user if user && LowAuth.can_login.call(user)
      end

      # Sets the user's password from a link, which uses it up, and logs them out everywhere else. Returns the user, or
      # nil when the link doesn't work or the password is too short.
      def use(token, password)
        user = user(token)
        return unless user && Passwords.long_enough?(password)

        LowAuth.database.transaction do
          LowAuth.users.where(id: user[:id]).update(password_hash: Passwords.digest(password))
          table.where(user_id: user[:id]).delete
          Sessions.destroy_all(user_id: user[:id])
        end
        user
      end

      private

      def table
        LowAuth.database[:password_links]
      end

      def digest(token)
        Digest::SHA256.hexdigest(token.to_s)
      end
    end
  end
end
