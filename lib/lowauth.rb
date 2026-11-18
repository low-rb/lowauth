# frozen_string_literal: true

require 'sequel'
require 'uri'

require_relative 'version'
require_relative 'lowauth/passwords'
require_relative 'lowauth/sessions'
require_relative 'lowauth/login_limit'
require_relative 'lowauth/guard'
require_relative 'lowauth/node_helpers'

# Logins for Raindeer: passwords, sessions in a database table and a cookie, and guards on nodes.
module LowAuth
  class ConfigError < StandardError; end

  class << self
    # The Sequel database with the users and sessions tables.
    attr_writer :database
    # The users table, and the columns a user can log in with, like username or email.
    attr_accessor :users_table, :login_columns
    # Checks a password against a user's old hash, from a site the users came from, until they log in and it's rehashed.
    attr_accessor :legacy_password
    # Whether a user may log in at all, like when they aren't blocked.
    attr_accessor :can_login
    # Each role a node can require, and how to tell if a user has it: { admin: ->(user) { user[:role] == 'admin' } }.
    attr_accessor :roles
    attr_accessor :cookie_name, :session_days, :secure_cookies

    def configure
      yield self
    end

    def database
      @database || raise(ConfigError, 'Set the database, e.g. LowAuth.database = DB')
    end

    def users
      database[users_table]
    end

    # The logged in user of the request an event came from, or nil.
    def current_user(event)
      token = event.cookies[cookie_name]
      return unless token

      Sessions.user(token)
    end

    def role?(user, role)
      return !user.nil? if role.nil?
      return false unless user

      check = roles.fetch(role) { raise ConfigError, "There's no #{role} role in LowAuth.roles" }
      check.call(user)
    end

    # Whether a form was sent from this site, by its Origin header, which browsers send with a form and sites can't fake.
    def same_origin?(event)
      headers = event.request.headers
      origin = Array(headers['origin']).first || Array(headers['referer']).first
      return false unless origin

      authority(URI(origin)) == Array(headers['host']).first
    rescue URI::InvalidURIError
      false
    end

    private

    # A URI's host, and its port when it isn't the scheme's usual one, as a Host header has them.
    def authority(uri)
      return uri.host if uri.port == uri.default_port

      "#{uri.host}:#{uri.port}"
    end
  end

  self.users_table = :users
  self.login_columns = %i[username email]
  self.legacy_password = nil
  self.can_login = ->(_user) { true }
  self.roles = {}
  self.cookie_name = 'session'
  self.session_days = 30
  self.secure_cookies = true
end
