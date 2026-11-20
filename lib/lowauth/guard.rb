# frozen_string_literal: true

require 'cgi'

module LowAuth
  # "allows { |user| ... }" in a node lets only the users its block is true for call its actions, like
  # "allows { |user| LowAuth.role?(user, :admin) }". "requires :admin" is short for that, and "requires" for any logged in
  # user. The block is also the node's "allowed?(user)", so a menu can ask whether to link to it.
  # Anyone else gets nothing, so the router moves on and responds with a 404, which doesn't say there's a page. With
  # config.login_path set, a logged out visitor reading a page is sent to log in instead, and back to it after.
  # Actions that change things, like "receive" and "post", also need the form to come from this site.
  module Guard
    READS = %i[render get query side_effect].freeze

    def allows(&rule)
      define_singleton_method(:allowed?) { |user| rule.call(user) ? true : false }
      singleton_class.prepend(Guard.module_for_actions)
    end

    def requires(role = nil)
      allows { |user| LowAuth.role?(user, role) }
    end

    # Whether an event's user may call an action, by the node's rule, with a form from this site for one that changes things.
    def self.allowed?(node, event, action)
      return false unless event && node.allowed?(LowAuth.current_user(event))

      READS.include?(action) || LowAuth.same_origin?(event)
    end

    # What a node answers someone it doesn't allow: nothing, or a logged out visitor reading it is sent to log in.
    def self.refusal(node, event, action)
      location = login_location(event, action)
      node.send(:response_event, body: Low::Responses::Redirect.new(location:, status: 303), event:) if location
    end

    # Where a logged out visitor reading a guarded page goes to log in, coming back to it after, or nil.
    def self.login_location(event, action)
      return unless LowAuth.login_path && READS.include?(action) && event && LowAuth.current_user(event).nil?

      path = event.respond_to?(:path) ? event.path : nil
      return LowAuth.login_path unless path

      "#{LowAuth.login_path}?redirect=#{CGI.escape(path)}"
    end

    def self.module_for_actions
      Module.new do
        (Low::Templates::Renderer::ACTIONS + Low::Templates::Renderer::CONTROLLER_ACTIONS).each do |action|
          define_method(action) do |**kwargs|
            return unless defined?(super)
            return Guard.refusal(self, kwargs[:event], action) unless Guard.allowed?(self, kwargs[:event], action)

            super(**kwargs)
          end
        end
      end
    end
  end
end
