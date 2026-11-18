# frozen_string_literal: true

module LowAuth
  # "requires :admin" in a node lets only users with that role call its actions, and "requires" any logged in user.
  # Anyone else gets nothing, so the router moves on and responds with a 404, which doesn't say there's a page.
  # Actions that change things, like "receive" and "post", also need the form to come from this site.
  module Guard
    READS = %i[render get query side_effect].freeze

    def requires(role = nil)
      singleton_class.prepend(guard(role))
    end

    def self.allowed?(event, action, role)
      return false unless event && LowAuth.role?(LowAuth.current_user(event), role)

      READS.include?(action) || LowAuth.same_origin?(event)
    end

    private

    def guard(role)
      Module.new do
        (Low::Templates::Renderer::ACTIONS + Low::Templates::Renderer::CONTROLLER_ACTIONS).each do |action|
          define_method(action) do |**kwargs|
            return unless defined?(super) && Guard.allowed?(kwargs[:event], action, role)

            super(**kwargs)
          end
        end
      end
    end
  end
end
