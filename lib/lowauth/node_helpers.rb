# frozen_string_literal: true

module LowAuth
  # Logging in and out from a node, which sets or expires the session cookie with the node's response.
  module NodeHelpers
    def current_user(event)
      LowAuth.current_user(event)
    end

    def log_in(user, event:)
      headers = event.request.headers
      token = Sessions.create(user_id: user[:id], ip: Array(headers['x-forwarded-for']).first,
                              user_agent: Array(headers['user-agent']).first)
      set_cookie(LowAuth.cookie_name, token, max_age: LowAuth.session_days * 86_400, secure: LowAuth.secure_cookies)
    end

    def log_out(event:)
      token = event.cookies[LowAuth.cookie_name]
      Sessions.destroy(token) if token
      set_cookie(LowAuth.cookie_name, '', max_age: 0, secure: LowAuth.secure_cookies)
    end
  end
end
