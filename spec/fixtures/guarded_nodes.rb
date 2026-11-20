# frozen_string_literal: true

module LowAuthSpec
  class AdminNode < LowNode
    extend LowAuth::Guard
    include Controller

    allows :admin

    def get = 'admin page'
    def post = 'posted'
  end

  class EditorsNode < LowNode
    extend LowAuth::Guard
    include Controller

    allows { |user| user && user[:username].start_with?('ed') }

    def get = 'editors page'
  end

  class MembersNode < LowNode
    extend LowAuth::Guard
    include Controller

    allows

    def get = 'members page'
  end
end

module LowAuthSpec
  class SessionNode < LowNode
    include LowAuth::NodeHelpers
  end
end
