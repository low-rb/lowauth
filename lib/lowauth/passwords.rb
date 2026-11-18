# frozen_string_literal: true

require 'argon2'

module LowAuth
  # Hashes passwords with Argon2, and logs users in with them. A user with only an old hash from another site, like
  # Drupal's, logs in with LowAuth.legacy_password, which rehashes their password with Argon2.
  module Passwords
    # Verified when there's no such user, so a login takes as long whether or not the user exists.
    DECOY_HASH = Argon2::Password.create(SecureRandom.hex(16))

    class << self
      def digest(password)
        Argon2::Password.create(password)
      end

      # The user a login and password belong to, or nil.
      def authenticate(login, password)
        user = find_user(login.to_s.strip)
        return decoy(password) unless user
        return unless LowAuth.can_login.call(user)
        return user if user[:password_hash] && Argon2::Password.verify_password(password, user[:password_hash])

        upgrade(user, password)
      end

      private

      def find_user(login)
        return if login.empty?

        matches = LowAuth.login_columns.map { |column| { Sequel.function(:lower, column) => login.downcase } }
        LowAuth.users.where(Sequel.|(*matches)).first
      end

      def upgrade(user, password)
        return if user[:password_hash] || LowAuth.legacy_password.nil?
        return unless LowAuth.legacy_password.call(user, password)

        LowAuth.users.where(id: user[:id]).update(password_hash: digest(password))
        user
      end

      def decoy(password)
        Argon2::Password.verify_password(password, DECOY_HASH)
        nil
      end
    end
  end
end
