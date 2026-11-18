# frozen_string_literal: true

module LowAuth
  # Stops guessing passwords: after 10 failed logins for a key, like a login name or an IP, in 15 minutes, it waits.
  # It's kept in memory, so it's per process and starts again when the server does.
  module LoginLimit
    ATTEMPTS = 10
    WINDOW = 15 * 60

    @failures = Hash.new { |hash, key| hash[key] = [] }
    @mutex = Mutex.new

    class << self
      def allowed?(key)
        @mutex.synchronize { recent(key).size < ATTEMPTS }
      end

      def failed(key)
        @mutex.synchronize { recent(key) << Time.now }
      end

      def clear(key)
        @mutex.synchronize { @failures.delete(key) }
      end

      private

      def recent(key)
        @failures[key].select! { |time| time > Time.now - WINDOW }
        @failures[key]
      end
    end
  end
end
