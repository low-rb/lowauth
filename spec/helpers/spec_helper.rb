# frozen_string_literal: true

require 'lownode'
require_relative '../../lib/lowauth'

# A database with the tables LowAuth uses, and an event like Raindeer's, with a request's cookies and headers.
module LowAuthSpec
  Request = Struct.new(:headers)
  Event = Struct.new(:cookies, :request) do
    def self.from(cookies: {}, headers: {})
      new(cookies, Request.new({ 'host' => 'example.com' }.merge(headers)))
    end
  end

  def self.database
    Sequel.sqlite.tap do |db|
      db.create_table(:users) do
        primary_key :id
        String :username
        String :email
        String :role
        String :password_hash
        String :old_hash
        TrueClass :blocked, default: false
      end
      db.create_table(:sessions) do
        primary_key :id
        String :token_digest, unique: true
        Integer :user_id
        String :ip
        String :user_agent
        DateTime :created_at
        DateTime :expires_at
      end
      db.create_table(:password_links) do
        primary_key :id
        String :token_digest, unique: true
        Integer :user_id
        DateTime :created_at
        DateTime :expires_at
      end
    end
  end
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!

  config.before do
    LowAuth.database = LowAuthSpec.database
    LowAuth.legacy_password = ->(user, password) { user[:old_hash] == "old:#{password}" }
    LowAuth.can_login = ->(user) { !user[:blocked] }
    LowAuth.roles = { admin: ->(user) { user[:role] == 'admin' } }
  end
end

require_relative '../fixtures/guarded_nodes'
